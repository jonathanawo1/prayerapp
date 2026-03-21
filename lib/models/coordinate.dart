import 'package:google_maps_flutter/google_maps_flutter.dart';

class Coordinate {
  final double latitude;
  final double longitude;

  const Coordinate({required this.latitude, required this.longitude});

  factory Coordinate.fromJson(Map<String, dynamic> json) => Coordinate(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
      };

  LatLng toLatLng() => LatLng(latitude, longitude);

  @override
  String toString() => 'Coordinate($latitude, $longitude)';
}
