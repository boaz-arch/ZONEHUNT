
import '../../services/socket_service.dart';


class GameSocketListener {
  final void Function(String phase, DateTime? endsAt) onZoneTimerUpdated;
  final void Function(List rawPlayers) onPositionsUpdated;
  final void Function(List rawPlayers, dynamic caughtPlayerId) onPlayerCaught;
  final void Function(Map zoneState, int durationMs) onZoneUpdated;
  final void Function(Map<String, dynamic> rawRedZone) onRedZoneUpdated;
  final void Function(String winner) onGameEnded;

  GameSocketListener({
    required this.onZoneTimerUpdated,
    required this.onPositionsUpdated,
    required this.onPlayerCaught,
    required this.onZoneUpdated,
    required this.onRedZoneUpdated,
    required this.onGameEnded,
  });

  void register() {
    SocketService.socket.on("zoneTimerUpdated", _handleZoneTimerUpdated);
    SocketService.socket.on("positionsUpdated", _handlePositionsUpdated);
    SocketService.socket.on("playerCaught", _handlePlayerCaught);
    SocketService.socket.on("zoneUpdated", _handleZoneUpdated);
    SocketService.socket.on("redZoneUpdated", _handleRedZoneUpdated);
    SocketService.socket.on("gameEnded", _handleGameEnded);
  }

  void _handleZoneTimerUpdated(dynamic data) {
    final endsAt = data["phaseEndsAt"] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(data["phaseEndsAt"]);

    onZoneTimerUpdated(data["phase"], endsAt);
  }

  void _handlePositionsUpdated(dynamic players) {
    onPositionsUpdated(players as List);
  }

  void _handlePlayerCaught(dynamic data) {
    onPlayerCaught(data["players"] as List, data["playerId"]);
  }

  void _handleZoneUpdated(dynamic data) {
    final zoneState = data["zoneState"];
    if (zoneState == null) return;

    final durationMs = (data["durationMs"] as num?)?.toInt() ?? 0;
    onZoneUpdated(zoneState, durationMs);
  }

  void _handleRedZoneUpdated(dynamic data) {
    onRedZoneUpdated(Map<String, dynamic>.from(data));
  }

  void _handleGameEnded(dynamic data) {
    onGameEnded(data["winner"]);
  }

  void dispose() {
    SocketService.socket.off("positionsUpdated");
    SocketService.socket.off("playerCaught");
    SocketService.socket.off("zoneUpdated");
    SocketService.socket.off("redZoneUpdated");
    SocketService.socket.off("gameEnded");
    SocketService.socket.off("zoneTimerUpdated");
  }
}
