import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Represents a ski lift with name and identifier.
class SkiLift {
  final String name;
  final String range; // e.g., "A1-A4"
  SkiLift({required this.name, required this.range});
}

/// Represents an arrival point with name and elevation.
class ArrivalPoint {
  final String name;
  final int elevationMeters;
  ArrivalPoint({required this.name, required this.elevationMeters});
}

/// Represents a piste with name and difficulty color.
class Piste {
  final String name;
  final String difficulty; // "Black", "Blue", "Red"
  Piste({required this.name, required this.difficulty});
}

class MapLocation {
  final String id;
  final String name;
  final LatLng position;
  final String? address;
  final double? rating;
  final int? userRatingsTotal;
  final String? type; // e.g., "lodging", "point_of_interest"

  static const String typeMountain = 'mountain';
  static const String typeHotel = 'hotel';
  static const String typeCamera = 'camera';
  static const String typeDot = 'dot';
  /// Zone: translucent purple circle with white dot at center
  static const String typeZone = 'zone';

  /// Optional circle radius in meters (for typeZone).
  final double? circleRadius;

  // Ski resort specific data
  final String? skiLiftsRange;      // e.g., "A1-A4"
  final String? turnstilesRange;    // e.g., "T1-T11"
  final List<ArrivalPoint>? arrivalPoints;
  final List<Piste>? pistes;

  MapLocation({
    required this.id,
    required this.name,
    required this.position,
    this.address,
    this.rating,
    this.userRatingsTotal,
    this.type,
    this.circleRadius,
    this.skiLiftsRange,
    this.turnstilesRange,
    this.arrivalPoints,
    this.pistes,
  });
}
