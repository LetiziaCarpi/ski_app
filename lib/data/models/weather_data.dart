class WeatherData {
  final double temperature;
  final int weatherCode;
  final double highTemp;
  final double lowTemp;
  final int humidity;
  final double windSpeed;
  final String sunrise;
  final String sunset;
  final double uvIndex;
  final double pressure;
  final List<HourlyForecast> hourly;

  WeatherData({
    required this.temperature,
    required this.weatherCode,
    required this.highTemp,
    required this.lowTemp,
    required this.humidity,
    required this.windSpeed,
    required this.sunrise,
    required this.sunset,
    required this.uvIndex,
    required this.pressure,
    required this.hourly,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final current = json['current'];
    final daily = json['daily'];
    final hourly = json['hourly'];

    // Helper to get today's index (usually 0)
    // Open-Meteo returns arrays for daily/hourly
    
    return WeatherData(
      temperature: (current['temperature_2m'] as num).toDouble(),
      weatherCode: current['weather_code'] as int,
      highTemp: (daily['temperature_2m_max'][0] as num).toDouble(),
      lowTemp: (daily['temperature_2m_min'][0] as num).toDouble(),
      humidity: (current['relative_humidity_2m'] as num).toInt(),
      windSpeed: (current['wind_speed_10m'] as num).toDouble(),
      sunrise: daily['sunrise'][0] as String,
      sunset: daily['sunset'][0] as String,
      uvIndex: (daily['uv_index_max'][0] as num).toDouble(),
      pressure: (current['surface_pressure'] as num).toDouble(),
      hourly: _parseHourly(hourly),
    );
  }

  static List<HourlyForecast> _parseHourly(Map<String, dynamic> hourly) {
    final List<HourlyForecast> list = [];
    final times = hourly['time'] as List;
    final temps = hourly['temperature_2m'] as List;
    final codes = hourly['weather_code'] as List;

    // Open-Meteo returns 7 days of hourly data. We just want the next 24h or so.
    // Let's take every 3rd hour for display or just first few.
    // We'll take next 5 slots for the dashboard.
    
    // Ideally we should find the current hour index, but for simplicity we take the first 5 
    // assuming the API returns data starting from "now" or 00:00 of today.
    // Actually Open-Meteo returns from 00:00 today.
    
    final now = DateTime.now();
    int startIndex = 0;
    for (int i = 0; i < times.length; i++) {
      if (DateTime.parse(times[i]).isAfter(now)) {
        startIndex = i;
        break;
      }
    }

    for (int i = startIndex; i < startIndex + 5 && i < times.length; i++) {
      list.add(HourlyForecast(
        time: times[i],
        temp: (temps[i] as num).toDouble(),
        code: codes[i] as int,
      ));
    }
    return list;
  }
}

class HourlyForecast {
  final String time;
  final double temp;
  final int code;

  HourlyForecast({required this.time, required this.temp, required this.code});
}
