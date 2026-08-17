import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import 'services/api_service.dart';
import 'services/socket_service.dart';
import 'player_data.dart';

import 'gameplay/gameplay_screen.dart';
import 'gameplay/models/zone_state.dart';
import 'gameplay/widgets/zone_layers.dart';
import 'gameplay/widgets/player_markers.dart';
import 'gameplay/widgets/outside_zone_banner.dart';
import 'gameplay/gps/gps_controller.dart';
import 'gameplay/utils/geo_utils.dart' as geo;
import 'gameplay/widgets/remaining_hiders_panel.dart';
import 'gameplay/models/player.dart';

class HidePhaseScreen extends StatefulWidget {
  final int hidePhaseEndsAt;
  final String role;
  final String gameCode;
  final double centerLat;
  final double centerLng;
  final double radius;
  final bool anonymousMode;

  const HidePhaseScreen({
    super.key,
    required this.hidePhaseEndsAt,
    required this.role,
    required this.gameCode,
    required this.centerLat,
    required this.centerLng,
    required this.radius,
    required this.anonymousMode,
  });

  @override
  State<HidePhaseScreen> createState() =>
      _HidePhaseScreenState();
}

class _HidePhaseScreenState
    extends State<HidePhaseScreen> {

  final MapController mapController =
      MapController();

  Position? currentPosition;

  List<Map<String, dynamic>> teammates = [];

  bool showPlayerList = false;

  Timer? timer;

  int secondsRemaining = 0;

  bool navigatedToGameplay = false;

  late ZoneState zone;

  late final GpsController gps;

  Future<void> loadInitialTeammates() async {
    final positions =
        await ApiService.getPositions(
      widget.gameCode,
    );

    if (positions == null || !mounted) {
      return;
    }

   setState(() {
      teammates =
          List<Map<String, dynamic>>.from(
        positions,
      );
    });

  }

  Map<String, int> getPlayerNumbers() {
    final numbers = <String, int>{};

    int hunterCount = 0;
    int hiderCount = 0;

    for (final p in teammates) {
      if (p["role"] == "hunter") {
        hunterCount++;
        numbers[p["id"]] = hunterCount;
      } else {
        hiderCount++;
        numbers[p["id"]] = hiderCount;
      }
    }

    return numbers;
  }


  @override
  void initState() {
    super.initState();

    loadInitialTeammates();

    SocketService.socket.on(
      "positionsUpdated",
      (players) {
        setState(() {
          teammates =
              List<Map<String, dynamic>>.from(
            players,
          );
        });
      },
    );


    zone = ZoneState(
      currentCenterLat: widget.centerLat,
      currentCenterLng: widget.centerLng,
      displayedCenterLat: widget.centerLat,
      displayedCenterLng: widget.centerLng,
      displayedRadius: widget.radius,
    );

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
          LatLng(
            position.latitude,
            position.longitude,
          ),
          16,
        );
      },
      
      onStatusChanged: (status) {},

    );

  gps.initialize();

    updateTimer();

    timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        updateTimer();
      },
    );


    SocketService.socket.on(
      "gameplayStarted",
      goToGameplay,
    );
  }

  void updateTimer() {
    final now =
        DateTime.now()
            .millisecondsSinceEpoch;

    final remaining =
        ((widget.hidePhaseEndsAt - now) /
                1000)
            .floor();

    if (!mounted) return;

    setState(() {
      secondsRemaining =
          remaining > 0
              ? remaining
              : 0;
    });
  }

  String formatTime() {
    final minutes =
        secondsRemaining ~/ 60;

    final seconds =
        secondsRemaining % 60;

    return
        "${minutes.toString().padLeft(2, '0')}:"
        "${seconds.toString().padLeft(2, '0')}";
  }

  LatLng getPlayerPoint() {
    if (currentPosition == null) {
      return LatLng(
        widget.centerLat,
        widget.centerLng,
      );
    }

    return LatLng(
      currentPosition!.latitude,
      currentPosition!.longitude,
    );
  }

  void goToGameplay(dynamic data) {

    if (navigatedToGameplay) {
      return;
    }

    navigatedToGameplay = true;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
          GameplayScreen(
            gameCode: widget.gameCode,
            role: widget.role,
            centerLat: data["zone"]["centerLat"],
            centerLng: data["zone"]["centerLng"],
            radius:
                (data["currentRadius"] ??
                        widget.radius)
                    .toDouble(),
            anonymousMode:
                widget.anonymousMode,
            timerTitle: null,
            timerEndsAt: null,
          ),
      ),
    );

  }

  @override
  void dispose() {

    SocketService.socket.off(
      "gameplayStarted",
    );

    SocketService.socket.off(
      "positionsUpdated",
    );

    timer?.cancel();
    gps.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerPoint =
        getPlayerPoint();

    final playerNumbers =
        getPlayerNumbers();

    final hiders = teammates
    .where((p) => p["role"] == "hider")
    .toList();

    final hunters = teammates
        .where((p) => p["role"] == "hunter")
        .toList();

    final hiderPlayers = hiders
        .map((p) => Player.fromJson(p))
        .toList();

    final hunterPlayers = hunters
        .map((p) => Player.fromJson(p))
        .toList();


    final outsideZone =
        geo.isOutsideZone(
      currentPosition: currentPosition,
      centerLat: widget.centerLat,
      centerLng: widget.centerLng,
      radius: widget.radius,
    );

    final distanceOutside =
        geo.distanceOutsideZone(
      currentPosition: currentPosition,
      centerLat: widget.centerLat,
      centerLng: widget.centerLng,
      radius: widget.radius,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult:
          (didPop, result) {},
      child: Container(
        decoration: BoxDecoration(
          border: outsideZone
              ? Border.all(
                  color:
                    secondsRemaining % 2 == 0
                        ? Colors.red
                        : Colors.red.withValues(
                            alpha: 0.4,
                          ),
                  width: 8,
                )
              : null,
        ),
        child: Scaffold(
          body: Stack(
            children: [

              Positioned.fill(
                child: FlutterMap(
                  mapController:
                      mapController,
                  options: MapOptions(
                    initialCenter: LatLng(
                      widget.centerLat,
                      widget.centerLng,
                    ),
                    initialZoom: 15,
                  ),
                   children: [
                    TileLayer(
                      urlTemplate:
                          "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                    ),

                    PolygonLayer(
                      polygons:
                          buildSafeZonePolygons(
                        zone,
                      ),
                    ),

                    CircleLayer(
                      circles:
                          buildZoneCircles(
                        zone: zone,
                        redZone: null,
                      ),
                    ),

                    MarkerLayer(
                      markers: [

                        buildOwnMarker(
                          point: playerPoint,
                          isCaught: false,
                          hunter:
                              widget.role ==
                                  "hunter",
                          number:
                            playerNumbers[
                                PlayerData.playerId] ??
                            1,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              RemainingHidersPanel(
                remainingHiders: hiderPlayers.length,
                showPlayerList: showPlayerList,
                onToggle: () {
                  setState(() {
                    showPlayerList = !showPlayerList;
                  });
                },
                hiders: hiderPlayers,
                hunters: hunterPlayers,
                playerNumbers: playerNumbers,
              ),

              Positioned(
                top: 10,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color:
                          widget.role == "hunter"
                              ? Colors.red
                              : Colors.green,
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                    child: Text(
                      widget.role.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(
                      alpha: 0.8,
                    ),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      const Text(
                        "HIDE PHASE",
                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      Text(
                        formatTime(),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Positioned(
                left: 0,
                right: 0,
                bottom: 20,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black
                          .withValues(
                        alpha: 0.8,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                    child: Text(
                      widget.role == "hunter"
                          ? "Wait for the hide phase to finish."
                          : "Find your hiding place before the hunt begins.",
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              if (outsideZone)
                OutsideZoneBanner(
                  distanceOutside:
                      distanceOutside,
                      secondsRemaining: -1,
                ),
            ],
          ),
        ),
      ),
    );
  }
}