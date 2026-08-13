import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/red_zone.dart';
import '../models/zone_state.dart';
import '../utils/zone_geometry.dart';


List<Polygon> buildSafeZonePolygons(
  ZoneState zone,
) {
  final hole = safeZoneHolePoints(
    centerLat: zone.displayedCenterLat,
    centerLng: zone.displayedCenterLng,
    radius: zone.displayedRadius,
  );

  const size = 1.0;

  final outer = [
    LatLng(
      zone.displayedCenterLat + size,
      zone.displayedCenterLng - size,
    ),
    LatLng(
      zone.displayedCenterLat + size,
      zone.displayedCenterLng + size,
    ),
    LatLng(
      zone.displayedCenterLat - size,
      zone.displayedCenterLng + size,
    ),
    LatLng(
      zone.displayedCenterLat - size,
      zone.displayedCenterLng - size,
    ),
  ];

  return [
    Polygon(
      points: outer,
      holePointsList: [hole],
      color: const Color.fromARGB(255, 16, 59, 200).withValues(alpha: 0.60),
    ),

    Polygon(
      points: hole,
      color: Colors.transparent,

      borderColor:  const Color.fromARGB(255, 16, 59, 200).withValues(alpha: 0.60),
      borderStrokeWidth: 1,
    ),
  ];
}

List<CircleMarker> buildZoneCircles({
  required ZoneState zone,
  required RedZone? redZone,
}) {
  return [
    CircleMarker(
      point: LatLng(zone.displayedCenterLat, zone.displayedCenterLng),
      radius: zone.displayedRadius,
      useRadiusInMeter: true,
      color: Colors.transparent,
      borderColor: const Color.fromARGB(255, 16, 59, 200).withValues(alpha: 0.60),

      borderStrokeWidth: 1,
    ),
    if (zone.nextCenterLat != null &&
        zone.nextCenterLng != null &&
        zone.nextRadius != null)
      CircleMarker(
        point: LatLng(zone.nextCenterLat!, zone.nextCenterLng!),
        radius: zone.nextRadius!,
        useRadiusInMeter: true,
        color: Colors.transparent,
        borderColor: const Color.fromARGB(255, 84, 88, 105).withValues(),

        borderStrokeWidth: 4,
      ),
    if (redZone != null)
      CircleMarker(
        point: LatLng(redZone.lat, redZone.lng),
        radius: redZone.radius,
        useRadiusInMeter: true,
        color: const Color.fromARGB(255, 255, 43, 28).withValues(alpha: 0.5),
      ),
  ];
}
