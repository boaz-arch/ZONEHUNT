import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

// Adjust these three imports to match your project's actual layout if it
// differs from lib/gameplay/... + lib/services/... + lib root.
import '../services/api_service.dart';
import '../player_data.dart';
import '../game_over_screen.dart';
import '../session.dart';

import 'models/player.dart';
import 'models/red_zone.dart';
import 'models/zone_state.dart';
import 'models/zone_timer_state.dart';
import 'gps/gps_controller.dart';
import 'sockets/game_socket_listener.dart';
import 'visibility/player_visibility.dart' as visibility;
import 'utils/geo_utils.dart' as geo;
import 'widgets/zone_layers.dart';
import 'widgets/player_markers.dart';
import 'widgets/remaining_hiders_panel.dart';
import 'widgets/zone_timer_panel.dart';
import 'widgets/outside_zone_banner.dart';
import 'widgets/caught_button.dart';

class GameplayScreen extends StatefulWidget {
  final String role;
  final String gameCode;

  final double centerLat;
  final double centerLng;
  final double radius;

  final bool anonymousMode;

  const GameplayScreen({
    super.key,
    required this.role,
    required this.centerLat,
    required this.centerLng,
    required this.radius,
    required this.gameCode,
    required this.anonymousMode,
  });

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen>
    with SingleTickerProviderStateMixin {
  List<Player> teammates = [];

  Position? currentPosition;
  late final GpsController gps;

  final MapController mapController = MapController();

  late ZoneState zone;
  late final AnimationController _radiusController;

  RedZone? redZone;

  final ZoneTimerState zoneTimer = ZoneTimerState();
  Timer? timerUpdate;

  bool isCaught = false;
  bool markingCaught = false;

  bool showPlayerList = false;

  late final GameSocketListener socketListener;

  @override
  void initState() {
    super.initState();

    timerUpdate = Timer.periodic(const Duration(seconds: 1), (_) {
      if (zoneTimer.endsAt == null) return;
      final remaining = zoneTimer.endsAt!.difference(DateTime.now()).inSeconds;

      setState(() {
        zoneTimer.secondsRemaining = remaining < 0 ? 0 : remaining;
      });
    });

    zone = ZoneState(
      currentCenterLat: widget.centerLat,
      currentCenterLng: widget.centerLng,
      displayedCenterLat: widget.centerLat,
      displayedCenterLng: widget.centerLng,
      displayedRadius: widget.radius,
    );

    _radiusController = AnimationController(vsync: this, duration: Duration.zero);

    gps = GpsController(
      gameCode: widget.gameCode,
      playerId: PlayerData.playerId,
      onPositionChanged: (position) {
        setState(() {
          currentPosition = position;
        });
      },
      onInitialFix: (position) {
        setState(() {
          currentPosition = position;
        });

        mapController.move(
          LatLng(position.latitude, position.longitude),
          16,
        );
      },
    );
    gps.initialize();

    loadInitialTeammates();

    socketListener = GameSocketListener(
      onZoneTimerUpdated: _onZoneTimerUpdated,
      onPositionsUpdated: _onPositionsUpdated,
      onPlayerCaught: _onPlayerCaught,
      onZoneUpdated: _onZoneUpdated,
      onRedZoneUpdated: _onRedZoneUpdated,
      onGameEnded: _onGameEnded,
    );
    socketListener.register();
  }

  void _onZoneTimerUpdated(String phase, DateTime? endsAt) {
    setState(() {
      zoneTimer.title = phase;
      zoneTimer.endsAt = endsAt;
    });
  }

  void _onPositionsUpdated(List rawPlayers) {
    setState(() {
      _setTeammates(rawPlayers);
      _syncCaughtFromTeammates();
    });
  }

  void _onPlayerCaught(List rawPlayers, dynamic caughtPlayerId) {
    setState(() {
      _setTeammates(rawPlayers);

      if (caughtPlayerId == PlayerData.playerId) {
        isCaught = true;
      }
    });
  }

  void _onZoneUpdated(Map zoneStateJson, int durationMs) {
    setState(() {
      zone.currentCenterLat = (zoneStateJson["currentCenterLat"] as num).toDouble();
      zone.currentCenterLng = (zoneStateJson["currentCenterLng"] as num).toDouble();
      zone.nextCenterLat = (zoneStateJson["nextCenterLat"] as num?)?.toDouble();
      zone.nextCenterLng = (zoneStateJson["nextCenterLng"] as num?)?.toDouble();
      zone.nextRadius = (zoneStateJson["nextRadius"] as num?)?.toDouble();
    });

    if (durationMs > 0 &&
        zoneStateJson["nextRadius"] != null &&
        zoneStateJson["nextCenterLat"] != null &&
        zoneStateJson["nextCenterLng"] != null) {
      animateToZone(
        (zoneStateJson["nextRadius"] as num).toDouble(),
        (zoneStateJson["nextCenterLat"] as num).toDouble(),
        (zoneStateJson["nextCenterLng"] as num).toDouble(),
        durationMs,
      );
    }
  }

  void _onRedZoneUpdated(Map<String, dynamic> rawRedZone) {
    setState(() {
      redZone = RedZone.fromJson(rawRedZone);
    });
  }

  void _onGameEnded(String winner) {
    goToGameOver(winner);
  }

  void _setTeammates(List rawPlayers) {
    teammates = Player.listFromJson(rawPlayers);
  }

  void _syncCaughtFromTeammates() {
    final me = _findPlayerById(PlayerData.playerId);
    if (me != null && me.caught) {
      isCaught = true;
    }
  }

  Player? _findPlayerById(String id) {
    for (final p in teammates) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<void> loadInitialTeammates() async {
    final positions = await ApiService.getPositions(widget.gameCode);
    if (positions == null || !mounted) return;

    setState(() {
      _setTeammates(positions);
      _syncCaughtFromTeammates();
    });
  }

  void goToGameOver(String winner) async {
    await clearSession();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => GameOverScreen(winner: winner, role: widget.role),
      ),
      (route) => false,
    );
  }

  Future<void> markCaught() async {
    if (markingCaught || isCaught) return;

    setState(() => markingCaught = true);

    final success = await ApiService.markCaught(widget.gameCode, PlayerData.playerId);

    if (!mounted) return;

    setState(() {
      markingCaught = false;
      if (success) isCaught = true;
    });
  }

  void animateToZone(
    double targetRadius,
    double targetLat,
    double targetLng,
    int durationMs,
  ) {
    if (durationMs <= 0) {
      setState(() {
        zone.displayedRadius = targetRadius;
        zone.displayedCenterLat = targetLat;
        zone.displayedCenterLng = targetLng;
      });
      return;
    }

    final startRadius = zone.displayedRadius;
    final startLat = zone.displayedCenterLat;
    final startLng = zone.displayedCenterLng;

    _radiusController.duration = Duration(milliseconds: durationMs);
    _radiusController.reset();

    final radiusAnimation = Tween<double>(begin: startRadius, end: targetRadius)
        .animate(CurvedAnimation(parent: _radiusController, curve: Curves.linear));

    final latAnimation = Tween<double>(begin: startLat, end: targetLat)
        .animate(CurvedAnimation(parent: _radiusController, curve: Curves.linear));

    final lngAnimation = Tween<double>(begin: startLng, end: targetLng)
        .animate(CurvedAnimation(parent: _radiusController, curve: Curves.linear));

    void listener() {
      setState(() {
        zone.displayedRadius = radiusAnimation.value;
        zone.displayedCenterLat = latAnimation.value;
        zone.displayedCenterLng = lngAnimation.value;
      });
    }

    radiusAnimation.addListener(listener);

    _radiusController.forward().whenCompleteOrCancel(() {
      radiusAnimation.removeListener(listener);
    });
  }


  LatLng getPlayerPoint() {
    if (currentPosition == null) {
      return LatLng(zone.displayedCenterLat, zone.displayedCenterLng);
    }
    return LatLng(currentPosition!.latitude, currentPosition!.longitude);
  }

  @override
  void dispose() {
    socketListener.dispose();
    _radiusController.dispose();
    gps.dispose();
    timerUpdate?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerPoint = getPlayerPoint();
    final mapCenter = playerPoint;


    final outsideZone = geo.isOutsideZone(
      currentPosition: currentPosition,
      centerLat: zone.displayedCenterLat,
      centerLng: zone.displayedCenterLng,
      radius: zone.displayedRadius,
    );

    final distanceOutside = geo.distanceOutsideZone(
      currentPosition: currentPosition,
      centerLat: zone.displayedCenterLat,
      centerLng: zone.displayedCenterLng,
      radius: zone.displayedRadius,
    );

    final visibleTeammates = visibility.getVisibleTeammates(
      teammates: teammates,
      myId: PlayerData.playerId,
      myRole: widget.role,
      redZone: redZone,
    );


    final playerNumbers = visibility.getPlayerNumbers(teammates);
    final hiders = visibility.getHiders(teammates);
    final hunters = visibility.getHunters(teammates);
    final remainingHiders = hiders.where((p) => !p.caught).length;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {},
      child: Container(
        decoration: BoxDecoration(
          border: outsideZone
              ? Border.all(color: Colors.red.withValues(alpha: 0.4), width: 8)
              : null,
        ),
        child: Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter: mapCenter,
                    initialZoom: 15,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    ),

                    PolygonLayer(polygons: buildSafeZonePolygons(zone)),

                    CircleLayer(
                      circles: buildZoneCircles(zone: zone, redZone: redZone),
                    ),

                    MarkerLayer(
                      markers: [
                        
                        buildOwnMarker(
                          point: playerPoint,
                          isCaught: isCaught,
                          hunter: widget.role == "hunter",
                          number: playerNumbers[PlayerData.playerId] ?? 1,
                        ),
                        ...visibleTeammates.map(
                          (p) => buildPlayerMarker(p, playerNumbers[p.id]!),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              RemainingHidersPanel(
                remainingHiders: remainingHiders,
                showPlayerList: showPlayerList,
                onToggle: () => setState(() => showPlayerList = !showPlayerList),
                hiders: hiders,
                hunters: hunters,
                playerNumbers: playerNumbers,
              ),

              ZoneTimerPanel(
                title: zoneTimer.title,
                endsAt: zoneTimer.endsAt,
                secondsRemaining: zoneTimer.secondsRemaining,
              ),

              if (outsideZone) OutsideZoneBanner(distanceOutside: distanceOutside),

              if (widget.role == "hider" && !isCaught)
                CaughtButton(isSubmitting: markingCaught, onPressed: markCaught),
            ],
          ),
        ),
      ),
    );
  }
}
