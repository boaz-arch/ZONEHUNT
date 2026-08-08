import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class FullMapScreen extends StatelessWidget {
  final double centerLat;
  final double centerLng;
  final int radius;

  const FullMapScreen({
    super.key,
    required this.centerLat,
    required this.centerLng,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final center = LatLng(
      centerLat,
      centerLng,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Zone Map",
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.all(12),
            color: Colors.grey.shade900,
            child: Column(
              children: [
                const Text(
                  "Selected Zone",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                Text(
                  "Radius: ${radius}m",
                ),

                Text(
                  "Lat: ${centerLat.toStringAsFixed(5)}",
                ),

                Text(
                  "Lng: ${centerLng.toStringAsFixed(5)}",
                ),
              ],
            ),
          ),

          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: 14,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                ),

                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: center,
                      radius:
                          radius.toDouble(),
                      useRadiusInMeter:
                          true,
                      color: Colors.blue
                          .withOpacity(
                              0.25),
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
                      point: center,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color:
                            Colors.red,
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