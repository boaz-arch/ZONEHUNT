import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class HidePhaseScreen extends StatefulWidget {
  final int hidePhaseEndsAt;
  final String role;

  const HidePhaseScreen({
    super.key,
    required this.hidePhaseEndsAt,
    required this.role,
  });

  @override
  State<HidePhaseScreen> createState() =>
      _HidePhaseScreenState();
}

class _HidePhaseScreenState
    extends State<HidePhaseScreen> {
  int secondsRemaining = 0;

  Timer? timer;

  Position? currentPosition;

  final MapController mapController =
      MapController();

  // Temporary values.
  // Next step will load these from server.
  double centerLat = 31.7683;
  double centerLng = 35.2137;

  double radius = 1000;

  @override
  void initState() {
    super.initState();

    updateTimer();

    startGps();

    timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        updateTimer();

        if (secondsRemaining <= 0) {
          timer.cancel();

          ScaffoldMessenger.of(context)
              .showSnackBar(
            const SnackBar(
              content: Text(
                "Hide Phase Ended",
              ),
            ),
          );
        }
      },
    );
  }

  Future<void> startGps() async {
    await Geolocator.requestPermission();

    final position =
        await Geolocator.getCurrentPosition();

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

    Geolocator.getPositionStream(
      locationSettings:
          const LocationSettings(
        accuracy:
            LocationAccuracy.high,
      ),
    ).listen((position) {
      setState(() {
        currentPosition = position;
      });
    });
  }

  void updateTimer() {
    final now =
        DateTime.now()
            .millisecondsSinceEpoch;

    final remaining =
        ((widget.hidePhaseEndsAt - now) /
                1000)
            .floor();

    setState(() {
      secondsRemaining =
          remaining > 0 ? remaining : 0;
    });
  }

  String formatTime() {
    final minutes =
        secondsRemaining ~/ 60;

    final seconds =
        secondsRemaining % 60;

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
      return LatLng(
        centerLat,
        centerLng,
      );
    }

    return LatLng(
      currentPosition!.latitude,
      currentPosition!.longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerPoint =
        getPlayerPoint();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Hide Phase",
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),

          const Text(
            "HIDE PHASE",
            style: TextStyle(
              fontSize: 32,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: roleColor(),
              borderRadius:
                  BorderRadius.circular(
                10,
              ),
            ),
            child: Text(
              roleText(),
              style:
                  const TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 20),

          Text(
            formatTime(),
            style: const TextStyle(
              fontSize: 60,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            widget.role == "hunter"
                ? "Wait for the hide phase to finish."
                : "Find your hiding place before the hunt begins.",
            textAlign:
                TextAlign.center,
          ),

          const SizedBox(height: 10),

          Expanded(
            child: FlutterMap(
              mapController:
                  mapController,
              options: MapOptions(
                initialCenter:
                    playerPoint,
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
                      point: LatLng(
                        centerLat,
                        centerLng,
                      ),
                      radius: radius,
                      useRadiusInMeter:
                          true,
                      color:
                          Colors.blue
                              .withOpacity(
                        0.2,
                      ),
                      borderColor:
                          Colors.blue,
                      borderStrokeWidth:
                          3,
                    ),
                  ],
                ),

                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(
                        centerLat,
                        centerLng,
                      ),
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
    );
  }
}