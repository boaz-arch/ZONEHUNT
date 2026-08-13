class RedZone {
  final double lat;
  final double lng;
  final double radius;

  const RedZone({required this.lat, required this.lng, required this.radius});

  factory RedZone.fromJson(Map<String, dynamic> json) {
    return RedZone(
      lat: (json["lat"] as num).toDouble(),
      lng: (json["lng"] as num).toDouble(),
      radius: (json["radius"] as num).toDouble(),
    );
  }
}
