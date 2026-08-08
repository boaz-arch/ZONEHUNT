import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class ZonePickerScreen extends StatefulWidget {
  const ZonePickerScreen({super.key});

  @override
  State<ZonePickerScreen> createState() =>
      _ZonePickerScreenState();
}

class _ZonePickerScreenState
    extends State<ZonePickerScreen> {
  LatLng selectedCenter =
      const LatLng(
    31.7683,
    35.2137,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Select Zone Center",
        ),
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: selectedCenter,
          initialZoom: 14,
          onTap: (
            tapPosition,
            point,
          ) {
            setState(() {
              selectedCenter = point;
            });
          },
        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          ),

          MarkerLayer(
            markers: [
              Marker(
                point: selectedCenter,
                width: 50,
                height: 50,
                child: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 50,
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: () {
          Navigator.pop(
            context,
            selectedCenter,
          );
        },
        label: const Text("Save"),
      ),
    );
  }
}