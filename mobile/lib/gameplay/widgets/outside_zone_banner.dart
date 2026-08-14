import 'package:flutter/material.dart';

class OutsideZoneBanner extends StatelessWidget {
  final double distanceOutside;
  final int secondsRemaining;

  const OutsideZoneBanner({
    super.key,
    required this.distanceOutside,
    required this.secondsRemaining,
  });

  

  @override
  Widget build(BuildContext context) {
    if (secondsRemaining < 0){
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
              "OUTSIDE SAFE ZONE\n"
              "${distanceOutside.round()}m\n"
              "ELIMINATION IN --",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }
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
            "OUTSIDE SAFE ZONE\n"
            "${distanceOutside.round()}m\n"
            "ELIMINATION IN ${secondsRemaining}s",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
