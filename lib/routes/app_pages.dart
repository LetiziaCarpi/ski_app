import 'package:get/get.dart';

import '../bindings/connect_binding.dart';
import '../views/connect_view.dart';
import '../bindings/map_binding.dart';
import '../views/map_view.dart';
import '../bindings/weather_binding.dart';
import '../views/weather_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const initial = Routes.connect;

  static final routes = [
    GetPage(
      name: _Paths.connect,
      page: () => const ConnectView(),
      binding: ConnectBinding(),
    ),
    GetPage(
      name: _Paths.map,
      page: () => const MapView(),
      binding: MapBinding(),
    ),
    GetPage(
      name: _Paths.weather,
      page: () => const WeatherView(),
      binding: WeatherBinding(),
    ),
  ];
}
