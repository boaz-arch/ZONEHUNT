import 'package:geolocator/geolocator.dart';
 
double distanceBetween(
  double lat1,
  double lng1,
  double lat2,
  double lng2,
) {
  return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
}
const zoneBuffer = 10;
 
bool isInsideCircle({
  required double pointLat,
  required double pointLng,
  required double centerLat,
  required double centerLng,
  required double radius,
}) {
  return distanceBetween(pointLat, pointLng, centerLat, centerLng) <= radius;
}
 
/// Same rule as the original `isOutsideZone()`.
bool isOutsideZone({
  required Position? currentPosition,
  required double centerLat,
  required double centerLng,
  required double radius,
}) {
  if (currentPosition == null) return false;
 
  return distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        centerLat,
        centerLng,
      ) >
      (radius + zoneBuffer);
}
 
/// Same rule as the original `getDistanceFromCenter()`.
double distanceFromCenter({
  required Position? currentPosition,
  required double centerLat,
  required double centerLng,
}) {
  if (currentPosition == null) return 0;
 
  return distanceBetween(
    currentPosition.latitude,
    currentPosition.longitude,
    centerLat,
    centerLng,
  );
}
 
/// Same rule as the original `getDistanceOutsideZone()`.
double distanceOutsideZone({
  required Position? currentPosition,
  required double centerLat,
  required double centerLng,
  required double radius,
}) {
  final distance = distanceFromCenter(
    currentPosition: currentPosition,
    centerLat: centerLat,
    centerLng: centerLng,
  );
 
  return (distance - radius).clamp(0, double.infinity);
}
 
/// Same formatting as the original `formatTime(int seconds)`.
String formatTime(int seconds) {
  final minutes = seconds ~/ 60;
  final secs = seconds % 60;
 
  return "${minutes.toString().padLeft(2, '0')}:"
      "${secs.toString().padLeft(2, '0')}";
}
 