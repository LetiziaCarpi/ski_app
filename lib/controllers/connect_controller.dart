import 'dart:io';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/geocoding.dart' as geocoding;
import '../../routes/app_pages.dart';
import '../services/iot_bridge_service.dart';
import '../data/models/map_location.dart';

class ConnectController extends GetxController {
  final isConnecting = false.obs;
  final isConnected = false.obs;
  final batteryLevel = 82.obs;
  final signalStrength = 'Strong'.obs;

  // Helmet Sensor Data
  final helmetTemp = 0.0.obs;
  final helmetHumidity = 0.obs;
  final helmetLux = 0.obs;
  final helmetFall = false.obs;
  final helmetAccel = <double>[0.0, 0.0, 0.0].obs;

  // Keep service alive here
  final IotBridgeService _iotService = IotBridgeService();
  
  // Geocoding service for reverse geocoding
  static const String _apiKey = "AIzaSyBA1CJG03TjIIaYeFRaWh3tbc6YBUNaVUk";
  final _geocodingService = geocoding.GoogleMapsGeocoding(apiKey: _apiKey);

  void connectToDevice() async {
    isConnecting.value = true;
    print("connectToDevice called");

    // 1. Request Permissions
    bool granted = await _checkPermissions();
    if (!granted) {
      isConnecting.value = false;
      Get.snackbar(
        "Permission Denied",
        "Please enable Bluetooth and Location permissions in settings to connect.",
        duration: const Duration(seconds: 4),
      );
      // Optional: Open settings if denied
      // openAppSettings();
      return;
    }

    // 2. Start Bridge
    try {
      print("pre listen");
      // Listen to sensor data
      _iotService.sensorData.listen((data) {
        isConnected.value = true;
        helmetTemp.value = (data['temp'] as num).toDouble();
        helmetHumidity.value = (data['hum'] as num).toInt();
        helmetLux.value = (data['lux'] as num).toInt();
        helmetFall.value = data['fall'] as bool;
        helmetAccel.value = (data['accel'] as List).cast<double>();
      });
      print("post listen");

      await _iotService.initBridge();
      // Note: initBridge is async but might return before connection is fully established.
      // For now we just start it as requested.
    } catch (e) {
      print("Bridge Error: $e");
    }

    // Simulate connection delay for UI
    await Future.delayed(const Duration(seconds: 2));

    isConnecting.value = false;

    // Navigate to Map View after connection
    Get.toNamed(Routes.map);
  }

  void goToDashboardWithLocation() async {
    try {
      // Get user location and navigate to dashboard
      MapLocation? userLocation = await _getUserLocation();
      Get.toNamed(Routes.weather, arguments: userLocation);
    } catch (e) {
      print("Error navigating to dashboard: $e");
      // Fallback: navigate without location
      Get.toNamed(Routes.weather);
    }
  }

  Future<MapLocation?> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print("Location services disabled");
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        print("Location permission not granted");
        return null;
      }

      final position = await Geolocator.getCurrentPosition();
      final latLng = LatLng(position.latitude, position.longitude);

      // Reverse Geocoding to get location name and address
      String name = "My Location";
      String address = "Unknown Address";

      try {
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
      } catch (e) {
        print("Reverse geocoding error: $e");
        // Continue with default name/address
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

      print("User location obtained: $name at ${latLng.latitude}, ${latLng.longitude}");
      return location;
    } catch (e) {
      print("Error getting user location: $e");
      return null;
    }
  }

  Future<bool> _checkPermissions() async {
    if (Platform.isAndroid) {
      // Android 12+ requires specific bluetooth permissions
      Map<Permission, PermissionStatus> statuses = await [
        Permission.location,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ].request();
      return statuses.values.every((status) => status.isGranted);
    } else {
      // iOS requires Bluetooth and Location
      // Request Location
      PermissionStatus locationStatus = await Permission.locationWhenInUse
          .request();

      // Request Bluetooth
      // On iOS, Permission.bluetooth maps to NSBluetoothAlwaysUsageDescription
      PermissionStatus bluetoothStatus = await Permission.bluetooth.request();

      // Check if both are granted
      // Note: On some iOS versions/simulators, bluetooth might return restricted/limited which is fine
      return locationStatus.isGranted &&
          (bluetoothStatus.isGranted || bluetoothStatus.isLimited);
    }
  }
}
