import 'package:flutter/material.dart';

import '../utils/geo_utils.dart';


class ZoneTimerPanel extends StatelessWidget {
  final String title;
  final DateTime? endsAt;
  final int secondsRemaining;

  const ZoneTimerPanel({
    super.key,
    required this.title,
    required this.endsAt,
    required this.secondsRemaining,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 10,
      top: 10,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              endsAt == null ? "— — : — —" : formatTime(secondsRemaining),
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
