import 'dart:math' as Math;

import 'package:latlong2/latlong.dart';

List<LatLng> safeZoneHolePoints({
  required double centerLat,
  required double centerLng,
  required double radius,
}) {
  const points = 120;

  return List.generate(points, (index) {
    final angle = (index / points) * 2 * Math.pi;
    final latOffset = (radius / 111320) * Math.sin(angle);
    final lngOffset =
        (radius / (111320 * Math.cos(centerLat * Math.pi / 180))) *
            Math.cos(angle);
    return LatLng(centerLat + latOffset, centerLng + lngOffset);
  });
}
