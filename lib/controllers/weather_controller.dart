import 'package:get/get.dart';
import '../services/weather_service.dart';
import '../data/models/map_location.dart';

class WeatherController extends GetxController {
  final WeatherService _weatherService = WeatherService();
  final isLoading = true.obs;

  // Header Data
  final location = 'Loading...'.obs;
  final temperature = 0.obs;
  final condition = 'Loading...'.obs;
  final highTemp = 0.obs;
  final lowTemp = 0.obs;

  // Quick Stats
  final humidity = 0.obs;
  final windSpeed = 0.obs;
  final sunrise = '--:--'.obs;

  // Slope Status (Mock Data for now)
  final slopeName = 'P2 - Blue'.obs;
  final safetyScore = 80.obs;
  final isSafe = true.obs;

  // Condition Report (Mock Data)
  final peopleOnSlope = 'Not Crowded'.obs;
  final accidents = '0 incidents'.obs;
  final visibility = 'Good visibility'.obs;
  final liftQueue = 'No Queue'.obs;

  // Environmental (Mock Data except what we fetch)
  final uvIndex = 0.obs;
  final uvLevel = 'Low'.obs;
  final rainHours = 2.8.obs;
  final windScaleMin = 2.obs;
  final windScaleMax = 4.obs;
  final airPressure = 1017.obs;
  final sunsetTime = '--:--'.obs;
  final sunriseTimeFull = '--:--'.obs;

  // Resort Info
  final totalPeople = 1240.obs;
  
  final slopeVisibility = [
    {'name': 'P1 Slope', 'status': 'Poor', 'value': 0.3},
    {'name': 'P2 Slope', 'status': 'Good', 'value': 0.8},
    {'name': 'P3 Slope', 'status': 'Fair', 'value': 0.6},
    {'name': 'P4 Slope', 'status': 'Good', 'value': 0.9},
  ].obs;

  final liftStatus = [
    {'name': 'Lift A1', 'status': 'Open', 'queue': 'No wait', 'isOpen': true},
    {
      'name': 'Lift A2',
      'status': 'Partially Open',
      'queue': 'Medium queue',
      'isOpen': true,
    },
    {'name': 'Lift A3', 'status': 'Open', 'queue': 'High Wait', 'isOpen': true},
    {
      'name': 'Lift A4',
      'status': 'Closed',
      'queue': '--------',
      'isOpen': false,
    },
  ].obs;

  // Hourly Forecast
  final hourlyForecast = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadData();
  }

  Future<void> _loadData() async {
    final args = Get.arguments;
    if (args is MapLocation) {
      location.value = args.name;
      await _fetchWeather(args.position.latitude, args.position.longitude);
    } else {
      // Default location (Marmolada)
      location.value = 'Marmolada';
      await _fetchWeather(46.4345, 11.8499);
    }
  }

  Future<void> _fetchWeather(double lat, double lng) async {
    isLoading.value = true;
    final data = await _weatherService.fetchWeather(lat, lng);
    
    if (data != null) {
      temperature.value = data.temperature.round();
      condition.value = WeatherService.getWeatherCondition(data.weatherCode);
      highTemp.value = data.highTemp.round();
      lowTemp.value = data.lowTemp.round();
      humidity.value = data.humidity;
      windSpeed.value = data.windSpeed.round();
      sunrise.value = data.sunrise.split('T').last;
      sunsetTime.value = data.sunset.split('T').last;
      sunriseTimeFull.value = data.sunrise.split('T').last;
      uvIndex.value = data.uvIndex.toInt();
      airPressure.value = data.pressure.toInt();

      hourlyForecast.value = data.hourly.map((h) {
        final dt = DateTime.parse(h.time);
        return {
          'time': '${dt.hour > 12 ? dt.hour - 12 : dt.hour} ${dt.hour >= 12 ? 'PM' : 'AM'}',
          'temp': h.temp.round(),
          'icon': _getIconStringForCode(h.code),
        };
      }).toList();
    }
    
    isLoading.value = false;
  }

  String _getIconStringForCode(int code) {
    if (code == 0) return 'cloudy'; // Clear usually sun but using cloudy as default
    if (code < 4) return 'cloudy';
    if (code < 50) return 'cloudy';
    if (code < 60) return 'rain';
    if (code < 70) return 'rain_heavy';
    if (code < 80) return 'snow';
    if (code < 90) return 'rain_sun';
    return 'storm';
  }
}
