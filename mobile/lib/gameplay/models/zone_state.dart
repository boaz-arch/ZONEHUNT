class ZoneState {
  double currentCenterLat;
  double currentCenterLng;

  double displayedCenterLat;
  double displayedCenterLng;
  double displayedRadius;

  double? nextCenterLat;
  double? nextCenterLng;
  double? nextRadius;

  ZoneState({
    required this.currentCenterLat,
    required this.currentCenterLng,
    required this.displayedCenterLat,
    required this.displayedCenterLng,
    required this.displayedRadius,
    this.nextCenterLat,
    this.nextCenterLng,
    this.nextRadius,
  });
}
