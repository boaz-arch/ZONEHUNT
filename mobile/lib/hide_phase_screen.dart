import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class HidePhaseScreen extends StatefulWidget {
  final int hidePhaseEndsAt;
  final String role;

  final double centerLat;
  final double centerLng;
  final double radius;

  const HidePhaseScreen({
    super.key,
    required this.hidePhaseEndsAt,
    required this.role,
    required this.centerLat,
    required this.centerLng,
    required this.radius,
  });

  @override
  State<HidePhaseScreen> createState() => _HidePhaseScreenState();
}

class _HidePhaseScreenState extends State<HidePhaseScreen> {
  int secondsRemaining = 0;

  Timer? timer;

  Position? currentPosition;

  final MapController mapController = MapController();

  @override
  void initState() {
    super.initState();

    updateTimer();

    startGps();

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      updateTimer();

      if (secondsRemaining <= 0) {
        timer.cancel();

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Hide Phase Ended")));
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

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    ).listen((position) {
      setState(() {
        currentPosition = position;
      });
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
    if (currentPosition == null) {
      return false;
    }

    final distance = Geolocator.distanceBetween(
      currentPosition!.latitude,
      currentPosition!.longitude,
      widget.centerLat,
      widget.centerLng,
    );

    return distance > widget.radius;
  }

  double getDistanceFromCenter() {
    if (currentPosition == null) {
      return 0;
    }

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

  Color roleColor() {
    if (widget.role == "hunter") {
      return Colors.red;
    }

    return Colors.green;
  }

  String roleText() {
    return widget.role.toUpperCase();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  LatLng getPlayerPoint() {
    if (currentPosition == null) {
      return LatLng(widget.centerLat, widget.centerLng);
    }

    return LatLng(currentPosition!.latitude, currentPosition!.longitude);
  }

  @override
  Widget build(BuildContext context) {
    final playerPoint = getPlayerPoint();

    final outsideZone = isOutsideZone();

    final distanceFromCenter = getDistanceFromCenter();

    final distanceOutside = getDistanceOutsideZone();

    return Container(
      decoration: BoxDecoration(
        border: outsideZone
            ? Border.all(
                color: secondsRemaining % 2 == 0
                    ? Colors.red
                    : Colors.red.withOpacity(0.4),
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
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
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
                        color: Colors.blue.withOpacity(0.20),
                        borderColor: Colors.blue,
                        borderStrokeWidth: 3,
                      ),
                    ],
                  ),

                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(widget.centerLat, widget.centerLng),
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),

                      Marker(
                        point: playerPoint,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.person_pin_circle,
                          color: Colors.green,
                          size: 40,
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
    );
  }
}
