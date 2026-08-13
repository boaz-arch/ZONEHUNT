import '../models/player.dart';
import '../models/red_zone.dart';
import '../utils/geo_utils.dart';

bool isInsideRedZone(RedZone? redZone, double lat, double lng) {
  if (redZone == null) return false;

  return isInsideCircle(
    pointLat: lat,
    pointLng: lng,
    centerLat: redZone.lat,
    centerLng: redZone.lng,
    radius: redZone.radius,
  );
}

List<Player> getVisibleTeammates({
  required List<Player> teammates,
  required String myId,
  required String myRole,
  required RedZone? redZone,
}) {
  return teammates.where((p) {
    final samePlayer = p.id == myId;
    final hasPos = p.position != null;

    if (samePlayer || !hasPos) return false;

    final exposed = isInsideRedZone(redZone, p.position!.lat, p.position!.lng);

    return exposed || p.role == myRole;
  }).toList();
}

List<Player> getHiders(List<Player> teammates) {
  return teammates.where((p) => p.role == "hider").toList();
}

List<Player> getHunters(List<Player> teammates) {
  return teammates.where((p) => p.role == "hunter").toList();
}

int getRemainingHiders(List<Player> teammates) {
  return getHiders(teammates).where((p) => !p.caught).length;
}

Map<String, int> getPlayerNumbers(List<Player> teammates) {
  final numbers = <String, int>{};
  final countByRole = <String, int>{};

  for (final p in teammates) {
    final next = (countByRole[p.role] ?? 0) + 1;
    countByRole[p.role] = next;
    numbers[p.id] = next;
  }

  return numbers;
}
