import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'services/api_service.dart';
import 'services/socket_service.dart';
import 'player_data.dart';
import 'gameplay_screen.dart';


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
    required this.centerLat,
    required this.centerLng,
    required this.radius,
    required this.gameCode,
    required this.anonymousMode,
  });

  @override
  State<HidePhaseScreen> createState() => _HidePhaseScreenState();
}

class _HidePhaseScreenState extends State<HidePhaseScreen> {

  List teammates = [];

  int secondsRemaining = 0;

  Timer? timer;

  Position? currentPosition;

  StreamSubscription<Position>? gpsSubscription;

  final MapController mapController = MapController();

  bool navigatedToGameplay = false;

  @override
  void initState() {
    super.initState();

    updateTimer();

    startGps();
    loadInitialTeammates();

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      updateTimer();

      // Local countdown is just a UI convenience; the server is the source
      // of truth and will push "gameplayStarted" independently.
      if (secondsRemaining <= 0) {
        timer.cancel();
      }
    });

    SocketService.socket.on("positionsUpdated", (players) {
      setState(() {
        teammates = (players as List);
      });
    });

    // Server-authoritative transition — fires even if this client's local
    // countdown drifted or it just reconnected moments before the switch.
    SocketService.socket.on("gameplayStarted", (data) {
      goToGameplay(data);
    });
  }

  void goToGameplay(dynamic data) {
    if (navigatedToGameplay) return;
    navigatedToGameplay = true;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GameplayScreen(
          gameCode: widget.gameCode,
          role: widget.role,
          centerLat: data["zone"]["centerLat"],
          centerLng: data["zone"]["centerLng"],
          radius: (data["currentRadius"] ?? widget.radius).toDouble(),
          anonymousMode: widget.anonymousMode,
        ),
      ),
    );
  }

  Future<void> loadInitialTeammates() async {
    final positions = await ApiService.getPositions(widget.gameCode);
    if (positions == null || !mounted) return;

    setState(() {
      teammates = positions;
    });
  }

  Future<void> startGps() async {
    await Geolocator.requestPermission();

    final position = await Geolocator.getCurrentPosition();

    setState(() {
      currentPosition = position;
    });

    mapController.move(LatLng(position.latitude, position.longitude), 16);
    
    gpsSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    ).listen((position) {
      setState(() {
        currentPosition = position;
      });
      ApiService.updatePosition(
        widget.gameCode,
        PlayerData.playerId,
        position.latitude,
        position.longitude,
      );
    });
  }

  void updateTimer() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final remaining = ((widget.hidePhaseEndsAt - now) / 1000).floor();

    setState(() {
      secondsRemaining = remaining > 0 ? remaining : 0;
    });
  }

  bool isOutsideZone() {
    if (currentPosition == null) return false;

    final distance = Geolocator.distanceBetween(
      currentPosition!.latitude,
      currentPosition!.longitude,
      widget.centerLat,
      widget.centerLng,
    );

    return distance > widget.radius;
  }

  double getDistanceFromCenter() {
    if (currentPosition == null) return 0;

    return Geolocator.distanceBetween(
      currentPosition!.latitude,
      currentPosition!.longitude,
      widget.centerLat,
      widget.centerLng,
    );
  }

  double getDistanceOutsideZone() {
    final distance = getDistanceFromCenter();
    return (distance - widget.radius).clamp(0, double.infinity);
  }

  String formatTime() {
    final minutes = secondsRemaining ~/ 60;
    final seconds = secondsRemaining % 60;
    return "${minutes.toString().padLeft(2, "0")}:${seconds.toString().padLeft(2, "0")}";
  }

  Color roleColor() => widget.role == "hunter" ? Colors.red : Colors.green;

  String roleText() => widget.role.toUpperCase();

  @override
  void dispose() {
    SocketService.socket.off("positionsUpdated");
    SocketService.socket.off("gameplayStarted");
    timer?.cancel();
    gpsSubscription?.cancel();
    super.dispose();
  }

  LatLng getPlayerPoint() {
    if (currentPosition == null) {
      return LatLng(widget.centerLat, widget.centerLng);
    }
    return LatLng(currentPosition!.latitude, currentPosition!.longitude);
  }

  List getVisibleTeammates() {
    return teammates.where((p) {
      return p["id"] != PlayerData.playerId &&
          p["role"] == widget.role &&
          p["position"] != null &&
          p["position"]["lat"] != null &&
          p["position"]["lng"] != null;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final playerPoint = getPlayerPoint();
    final outsideZone = isOutsideZone();
    final distanceFromCenter = getDistanceFromCenter();
    final distanceOutside = getDistanceOutsideZone();
    final visibleTeammates = getVisibleTeammates();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {},
      child: Container(
        decoration: BoxDecoration(
          border: outsideZone
              ? Border.all(
                  color: secondsRemaining % 2 == 0
                      ? Colors.red
                      : Colors.red.withValues(alpha: 0.4),
                  width: 8,
                )
              : null,
        ),
        child: Scaffold(
          appBar: AppBar(title: const Text("Hide Phase")),
          body: Column(
            children: [
              const SizedBox(height: 10),
              const Text(
                "HIDE PHASE",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: roleColor(),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  roleText(),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                formatTime(),
                style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                "Distance From Center: ${distanceFromCenter.round()}m",
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                "Zone Radius: ${widget.radius.round()}m",
                style: const TextStyle(fontSize: 16),
              ),
              if (outsideZone) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "⚠ OUTSIDE THE SAFE ZONE ⚠\n\n"
                    "Return to the zone immediately!\n\n"
                    "Distance Outside: ${distanceOutside.round()}m",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                widget.role == "hunter"
                    ? "Wait for the hide phase to finish."
                    : "Find your hiding place before the hunt begins.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Expanded(
                child: FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter: playerPoint,
                    initialZoom: 15,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    ),
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: LatLng(widget.centerLat, widget.centerLng),
                          radius: widget.radius,
                          useRadiusInMeter: true,
                          color: Colors.blue.withValues(alpha: 0.20),
                          borderColor: Colors.blue,
                          borderStrokeWidth: 3,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: playerPoint,
                          width: 80,
                          height: 80,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.person_pin_circle,
                                color: Colors.green,
                                size: 40,
                              ),
                              const Text(
                                "You",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...visibleTeammates.map(
                          (p) => Marker(
                            point: LatLng(
                              p["position"]["lat"],
                              p["position"]["lng"],
                            ),
                            width: 80,
                            height: 80,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.people,
                                  color: widget.role == "hunter"
                                      ? Colors.red
                                      : Colors.green,
                                  size: 35,
                                ),
                                Text(
                                  widget.anonymousMode
                                      ? "${p["role"] == "hunter" ? "Hunter" : "Hider"} ${String.fromCharCode(65 + visibleTeammates.indexOf(p))}"
                                      : p["name"],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}