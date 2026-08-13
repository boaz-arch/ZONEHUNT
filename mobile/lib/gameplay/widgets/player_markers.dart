import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/player.dart';

Marker buildOwnMarker({
  required LatLng point,
  required bool isCaught,
  required int number,
  required bool hunter,
}) {
  return Marker(
    point: point,
    width: 20,
    height: 20,
    child: Opacity(
      opacity: isCaught ? 0.4 : 1,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: hunter
              ? Colors.red
              : Colors.green,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            "$number",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ),
      ),
    ),
  );
}

Marker buildPlayerMarker(Player player, int number) {
  return Marker(
    point: LatLng(player.position!.lat, player.position!.lng),
    width: 20,
    height: 20,
    child: Opacity(
      opacity: player.caught ? 0.4 : 1.0,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: player.role == "hunter" ? Colors.red : Colors.green,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Center(
          child: Text(
            "$number",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ),
      ),
    ),
  );
}
