import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart' as places;
import 'package:google_maps_webservice/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';
import '../../core/values/app_colors.dart';
import '../../data/models/map_location.dart';
import '../../routes/app_pages.dart';
import '../services/weather_service.dart';

class MapController extends GetxController {
  late GoogleMapController mapController;
  final TextEditingController searchController = TextEditingController();

  // API Key - In production, use dart-define or .env
  static const String _apiKey = "AIzaSyBA1CJG03TjIIaYeFRaWh3tbc6YBUNaVUk";

  final _places = places.GoogleMapsPlaces(apiKey: _apiKey);
  final _geocodingService = geocoding.GoogleMapsGeocoding(apiKey: _apiKey);
  final _weatherService = WeatherService();

  final Rx<MapLocation?> selectedLocation = Rx<MapLocation?>(null);
  final RxSet<Marker> markers = <Marker>{}.obs;
  final RxSet<Circle> circles = <Circle>{}.obs;

  // Observable for basic weather in bottom sheet
  final currentTemp = '--'.obs;
  final currentCondition = '--'.obs;

  /// Cached marker icon – create once, reuse to avoid ImageReader buffer exhaustion on real devices.
  BitmapDescriptor? _cachedMarkerIcon;

  // Starting position: Marmolada (46.4345° N, 11.8499° E)
  final LatLng initialPosition = const LatLng(46.4345, 11.8499);

  /// Default location shown on map open – Marmolada with ski dialog data
  MapLocation get _defaultMarmoladaLocation => _createLocationWithSkiData(
    id: 'marmolada',
    name: 'Marmolada',
    position: initialPosition,
    address: 'Marmolada, Italy',
    rating: null,
  );

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
    // Load marker icon once
    _getOrCreateMarkerIcon().then((icon) {
      _cachedMarkerIcon = icon;
      // Instead of default Marmolada, try to get user location
      _getCurrentLocation();
    });
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Fallback to default if disabled
      _selectLocation(_defaultMarmoladaLocation);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _selectLocation(_defaultMarmoladaLocation);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _selectLocation(_defaultMarmoladaLocation);
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      final latLng = LatLng(position.latitude, position.longitude);

      // Reverse Geocoding
      String name = "My Location";
      String address = "Unknown Address";

      final response = await _geocodingService.searchByLocation(
        geocoding.Location(lat: latLng.latitude, lng: latLng.longitude),
      );

      if (response.isOkay && response.results.isNotEmpty) {
        final result = response.results.first;
        address = result.formattedAddress ?? address;
        // Use locality or sublocality for name if available
        for (var component in result.addressComponents) {
          if (component.types.contains("locality")) {
            name = component.longName;
            break;
          }
        }
      }

      final location = MapLocation(
        id: 'current_user',
        name: name,
        position: latLng,
        address: address,
        type: MapLocation.typeDot,
        // Empty ski data for user location
        skiLiftsRange: null,
        turnstilesRange: null,
        arrivalPoints: [],
        pistes: [],
      );

      _selectLocation(location);
    } catch (e) {
      print("Error getting location: $e");
      _selectLocation(_defaultMarmoladaLocation);
    }
  }

  void onMapTap(LatLng position) {
    selectedLocation.value = null;
    markers.clear();
    circles.clear();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> onSearchSubmitted(String query) async {
    if (query.trim().isEmpty) return;

    FocusManager.instance.primaryFocus?.unfocus();

    try {
      final response = await _places.searchByText(query);

      if (response.isOkay && response.results.isNotEmpty) {
        final result = response.results.first;
        final lat = result.geometry!.location.lat;
        final lng = result.geometry!.location.lng;
        final position = LatLng(lat, lng);

        final location = _createLocationWithSkiData(
          id: result.placeId,
          name: result.name,
          position: position,
          address: result.formattedAddress,
          rating: result.rating?.toDouble(),
        );

        _selectLocation(location);
      } else {
        Get.snackbar(
          'Location not found',
          'Could not find "$query".',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.black54,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Search failed: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  /// Creates a MapLocation with ski resort data based on the location name
  MapLocation _createLocationWithSkiData({
    required String id,
    required String name,
    required LatLng position,
    String? address,
    double? rating,
  }) {
    // Default ski resort data (can be customized per location)
    return MapLocation(
      id: id,
      name: name,
      position: position,
      address: address,
      rating: rating,
      type: MapLocation.typeMountain,
      skiLiftsRange: 'A1-A4',
      turnstilesRange: 'T1-T11',
      arrivalPoints: [
        ArrivalPoint(name: 'V1', elevationMeters: 1600),
        ArrivalPoint(name: 'V2', elevationMeters: 2650),
        ArrivalPoint(name: 'V3', elevationMeters: 2100),
      ],
      pistes: [
        Piste(name: 'P1', difficulty: 'Black'),
        Piste(name: 'P2', difficulty: 'Blue'),
        Piste(name: 'P3', difficulty: 'Red'),
        Piste(name: 'P4', difficulty: 'Red'),
      ],
    );
  }

  void _selectLocation(MapLocation location) {
    selectedLocation.value = location;

    // Fetch basic weather for the selected location
    _fetchBasicWeather(location.position);

    circles.clear();
    circles.add(
      Circle(
        circleId: CircleId('selection_${location.id}'),
        center: location.position,
        radius: 80,
        fillColor: AppColors.purpleAccent.withValues(alpha: 0.3),
        strokeWidth: 0,
      ),
    );

    markers.clear();
    _addPurpleCircleWithWhiteDotMarker(location);
    mapController.animateCamera(
      CameraUpdate.newLatLngZoom(location.position, 16),
    );
  }

  Future<void> _fetchBasicWeather(LatLng position) async {
    currentTemp.value = '--';
    currentCondition.value = 'Loading...';

    try {
      final data = await _weatherService.fetchWeather(
        position.latitude,
        position.longitude,
      );
      if (data != null) {
        currentTemp.value = '${data.temperature.round()}°';
        currentCondition.value = WeatherService.getWeatherCondition(
          data.weatherCode,
        );
      } else {
        currentCondition.value = 'Unavailable';
      }
    } catch (e) {
      print('Error fetching basic weather: $e');
      currentCondition.value = 'Error';
    }
  }

  /// Adds the reference-style marker: purple circle with white dot in center (not teardrop pin).
  /// Uses cached icon to avoid repeated bitmap creation (ImageReader buffer issues on real devices).
  Future<void> _addPurpleCircleWithWhiteDotMarker(MapLocation location) async {
    final icon = await _getOrCreateMarkerIcon();
    markers.add(
      Marker(
        markerId: MarkerId('center_${location.id}'),
        position: location.position,
        icon: icon,
        anchor: const Offset(0.5, 0.5),
        flat: true,
      ),
    );
  }

  /// Returns cached marker icon or creates it once. Reuse to avoid exhausting ImageReader buffers.
  Future<BitmapDescriptor> _getOrCreateMarkerIcon() async {
    if (_cachedMarkerIcon != null) return _cachedMarkerIcon!;
    _cachedMarkerIcon = await _createPurpleCircleWhiteDotBitmap();
    return _cachedMarkerIcon!;
  }

  /// Draws a purple circle with a white dot in the center (matches reference image).
  /// Called once and cached; smaller size (96) to reduce buffer pressure on devices.
  Future<BitmapDescriptor> _createPurpleCircleWhiteDotBitmap() async {
    const int size = 96;
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final double half = size / 2;

    const double radius = 34;
    const double whiteDotRadius = 10;

    // Outer purple circle (semi-transparent purple)
    final Paint purpleFill = Paint()
      ..color = AppColors.purpleAccent.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(half, half), radius, purpleFill);

    // Purple border
    final Paint purpleStroke = Paint()
      ..color = AppColors.purpleDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(Offset(half, half), radius, purpleStroke);

    // Inner white dot
    final Paint whiteDot = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(half, half), whiteDotRadius, whiteDot);

    final ui.Image image = await recorder.endRecording().toImage(size, size);
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  void goToDashboard() {
    Get.toNamed(Routes.weather, arguments: selectedLocation.value);
  }
}
