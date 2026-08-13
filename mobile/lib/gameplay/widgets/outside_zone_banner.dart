import 'package:flutter/material.dart';

class OutsideZoneBanner extends StatelessWidget {
  final double distanceOutside;

  const OutsideZoneBanner({super.key, required this.distanceOutside});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 120,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          width: 220,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            "OUTSIDE SAFE ZONE\n${distanceOutside.round()}m",
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
