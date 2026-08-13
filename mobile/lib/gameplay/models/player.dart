class PlayerPosition {
  final double lat;
  final double lng;

  const PlayerPosition({required this.lat, required this.lng});

  static PlayerPosition? fromJson(dynamic json) {
    if (json == null || json["lat"] == null || json["lng"] == null) {
      return null;
    }
    return PlayerPosition(
      lat: (json["lat"] as num).toDouble(),
      lng: (json["lng"] as num).toDouble(),
    );
  }
}

class Player {
  final String id;
  final String name;
  final String role;
  final bool caught;
  final PlayerPosition? position;

  const Player({
    required this.id,
    required this.name,
    required this.role,
    required this.caught,
    required this.position,
  });

  factory Player.fromJson(Map json) {
    return Player(
      id: json["id"] as String,
      name: (json["name"] ?? "") as String,
      role: json["role"] as String,
      caught: json["caught"] == true,
      position: PlayerPosition.fromJson(json["position"]),
    );
  }

  static List<Player> listFromJson(List raw) {
    return raw.map((p) => Player.fromJson(p as Map)).toList();
  }
}
