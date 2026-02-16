part of 'app_pages.dart';

abstract class Routes {
  Routes._();

  static const connect = _Paths.connect;
  static const map = _Paths.map;
  static const weather = _Paths.weather;
}

abstract class _Paths {
  _Paths._();

  static const connect = '/connect';
  static const map = '/map';
  static const weather = '/weather';
}
