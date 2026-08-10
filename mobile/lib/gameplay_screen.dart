import 'dart:async';
import 'dart:math' as Math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'services/api_service.dart';
import 'services/socket_service.dart';
import 'player_data.dart';
import 'game_over_screen.dart';
import 'session.dart';

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
  List teammates = [];

  Position? currentPosition;
  
  DateTime? lastPositionSent;
  Position? lastSentPosition;

  StreamSubscription<Position>? gpsSubscription;

  final MapController mapController = MapController();

  late double displayedRadius;
  late final AnimationController _radiusController;

  Map<String, dynamic>? redZone;

  bool isCaught = false;
  bool markingCaught = false;

  List<LatLng> getWorldBounds() {
    return [
      LatLng(85, -180),
      LatLng(85, 180),
      LatLng(-85, 180),
      LatLng(-85, -180),
    ];
  }

  List<LatLng> getSafeZoneHole() {
    const points = 120;
    
    return List.generate(points, (index) {
      final angle = (index / points) * 2 * Math.pi;
      final latOffset = (displayedRadius / 111320) * Math.sin(angle);
      final lngOffset = (displayedRadius / (111320 * Math.cos(widget.centerLat * Math.pi / 180))) * Math.cos(angle);
      return LatLng(widget.centerLat + latOffset, widget.centerLng + lngOffset);
    }); 
  }

  @override
  void initState() {
    super.initState();

    displayedRadius = widget.radius;

    _radiusController =
        AnimationController(vsync: this, duration: Duration.zero);

    startGps();
    loadInitialTeammates();

    SocketService.socket.on("positionsUpdated", (players) {
      setState(() {
        teammates = (players as List);

        final me = teammates.firstWhere(
          (p) => p["id"] == PlayerData.playerId,
          orElse: () => null,
        );

        if (me != null && me["caught"] == true) {
          isCaught = true;
        }
      });
    });

    SocketService.socket.on("playerCaught", (data) {
      setState(() {
        teammates = (data["players"] as List);

        if (data["playerId"] == PlayerData.playerId) {
          isCaught = true;
        }
      });
    });

    SocketService.socket.on("zoneUpdated", (data) {
      animateToRadius(
        (data["radius"] as num).toDouble(),
        (data["durationMs"] as num?)?.toInt() ?? 0,
      );
    });

    SocketService.socket.on("redZoneUpdated", (data) {
      setState(() {
        redZone = Map<String, dynamic>.from(data);
      });
    });

    SocketService.socket.on("gameEnded", (data) {
      goToGameOver(data["winner"]);
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

  void animateToRadius(double targetRadius, int durationMs) {
    if (durationMs <= 0) {
      setState(() => displayedRadius = targetRadius);
      return;
    }

    final startRadius = displayedRadius;

    _radiusController.duration = Duration(milliseconds: durationMs);
    _radiusController.reset();

    final animation = Tween<double>(begin: startRadius, end: targetRadius)
        .animate(CurvedAnimation(parent: _radiusController, curve: Curves.linear));

    void listener() {
      setState(() => displayedRadius = animation.value);
    }

    animation.addListener(listener);

    _radiusController.forward().whenCompleteOrCancel(() {
      animation.removeListener(listener);
    });
  }

  Future<void> loadInitialTeammates() async {
    final positions = await ApiService.getPositions(widget.gameCode);
    if (positions == null || !mounted) return;

    setState(() {
      teammates = positions;

      final me = teammates.firstWhere(
        (p) => p["id"] == PlayerData.playerId,
        orElse: () => null,
      );

      if (me != null && me["caught"] == true) {
        isCaught = true;
      }
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
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    ).listen((position) {

      setState(() {
        currentPosition = position;
      });

      final now = DateTime.now();

      if (lastPositionSent != null &&
          now.difference(lastPositionSent!).inSeconds < 1) {
        return;
      }

      if (lastSentPosition != null) {
        final movedDistance =
            Geolocator.distanceBetween(
          lastSentPosition!.latitude,
          lastSentPosition!.longitude,
          position.latitude,
          position.longitude,
        );

        if (movedDistance < 5 &&
            now.difference(lastPositionSent!)
                  .inSeconds < 1) {
          return;
        }
      }

      lastPositionSent = now;
      lastSentPosition = position;

      ApiService.updatePosition(
        widget.gameCode,
        PlayerData.playerId,
        position.latitude,
        position.longitude,
      );
    });
  }

  Future<void> markCaught() async {
    if (markingCaught || isCaught) return;

    setState(() => markingCaught = true);

    final success =
        await ApiService.markCaught(widget.gameCode, PlayerData.playerId);

    if (!mounted) return;

    setState(() {
      markingCaught = false;
      if (success) isCaught = true;
    });
  }

  bool isInsideRedZone(double lat, double lng) {
    if (redZone == null) return false;

    final distance = Geolocator.distanceBetween(
      lat,
      lng,
      (redZone!["lat"] as num).toDouble(),
      (redZone!["lng"] as num).toDouble(),
    );

    return distance <= (redZone!["radius"] as num).toDouble();
  }

  bool isOutsideZone() {
    if (currentPosition == null) return false;

    final distance = Geolocator.distanceBetween(
      currentPosition!.latitude,
      currentPosition!.longitude,
      widget.centerLat,
      widget.centerLng,
    );

    return distance > displayedRadius;
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
    return (distance - displayedRadius).clamp(0, double.infinity);
  }

  Color roleColor() => widget.role == "hunter" ? Colors.red : Colors.green;

  String roleText() => widget.role.toUpperCase();

  @override
  void dispose() {
    SocketService.socket.off("positionsUpdated");
    SocketService.socket.off("playerCaught");
    SocketService.socket.off("zoneUpdated");
    SocketService.socket.off("redZoneUpdated");
    SocketService.socket.off("gameEnded");
    _radiusController.dispose();
    gpsSubscription?.cancel();
    super.dispose();
  }

  LatLng getPlayerPoint() {
    if (currentPosition == null) {
      return LatLng(widget.centerLat, widget.centerLng);
    }
    return LatLng(currentPosition!.latitude, currentPosition!.longitude);
  }

  // Hunters only see hunters, hiders only see hiders — unless a player is
  // standing inside the red zone, in which case they're exposed to everyone.
  List getVisibleTeammates() {
    return teammates.where((p) {
      final samePlayer = p["id"] == PlayerData.playerId;
      final hasPos = p["position"] != null &&
          p["position"]["lat"] != null &&
          p["position"]["lng"] != null;

      if (samePlayer || !hasPos) return false;

      final exposed = isInsideRedZone(
        p["position"]["lat"],
        p["position"]["lng"],
      );

      return exposed || p["role"] == widget.role;
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
              ? Border.all(color: Colors.red.withValues(alpha: 0.4), width: 8)
              : null,
        ),
        child: Scaffold(
          appBar: AppBar(title: const Text("Game Active")),
          body: Column(
            children: [
              const SizedBox(height: 10),
              const Text(
                "GAME ACTIVE",
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
              const SizedBox(height: 10),
              Text(
                "Distance From Center: ${distanceFromCenter.round()}m",
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                "Zone Radius: ${displayedRadius.round()}m",
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
              if (widget.role == "hider" && !isCaught)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: markingCaught ? null : markCaught,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade800,
                      ),
                      child: markingCaught
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "I'VE BEEN CAUGHT",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ),
              if (isCaught)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    "You're out — spectating.",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
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
                    PolygonLayer(
                      polygons: [
                        Polygon(
                          points: getWorldBounds(),
                          holePointsList: [getSafeZoneHole(),],
                          color: Colors.blue.shade900.withValues(alpha: 0.35),
                        ),
                        Polygon(
                          points: getSafeZoneHole(),
                          color: Colors.transparent,
                          borderColor: Colors.blue,
                          borderStrokeWidth: 3,
                        ),
                      ],
                    ),
                    CircleLayer(
                      circles: [
                        CircleMarker(
                        point: LatLng(widget.centerLat, widget.centerLng),
                          radius: displayedRadius,
                          useRadiusInMeter: true,
                          color: Colors.transparent,
                          borderColor: Colors.blue,
                          borderStrokeWidth: 3,
                        ),
                        if (redZone != null)
                          CircleMarker(
                            point: LatLng(
                              (redZone!["lat"] as num).toDouble(),
                              (redZone!["lng"] as num).toDouble(),
                            ),
                            radius: (redZone!["radius"] as num).toDouble(),
                            useRadiusInMeter: true,
                            color: Colors.red.withValues(alpha: 0.25),
                            borderColor: Colors.redAccent,
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
                              Icon(
                                isCaught
                                    ? Icons.block
                                    : Icons.person_pin_circle,
                                color: isCaught ? Colors.grey : Colors.green,
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
                        ...visibleTeammates.map((p) {
                          final caught = p["caught"] == true;

                          return Marker(
                            point: LatLng(
                              p["position"]["lat"],
                              p["position"]["lng"],
                            ),
                            width: 80,
                            height: 80,
                            child: Opacity(
                              opacity: caught ? 0.4 : 1.0,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.people,
                                    color: p["role"] == "hunter"
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
                          );
                        }),
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