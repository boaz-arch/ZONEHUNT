import 'package:flutter/material.dart';

import '../gps/gps_status.dart';

/// Small top-of-screen banner explaining *why* your dot isn't updating,
/// instead of leaving the player staring at a frozen marker. Returns an
/// empty widget for [GpsStatus.ok] so it's safe to always include in the
/// widget tree.
class GpsStatusBanner extends StatelessWidget {
  final GpsStatus status;
  final VoidCallback? onRetry;

  const GpsStatusBanner({super.key, required this.status, this.onRetry});

  String? get _message {
    switch (status) {
      case GpsStatus.ok:
        return null;
      case GpsStatus.disabled:
        return "Location services are OFF. Enable GPS to keep playing.";
      case GpsStatus.permissionDenied:
        return "Location permission needed. Tap to grant access.";
      case GpsStatus.permissionDeniedForever:
        return "Location permission blocked. Enable it in system settings.";
      case GpsStatus.signalLost:
        return "GPS signal lost — trying to reconnect...";
      case GpsStatus.poorAccuracy:
        return "Weak GPS signal — your position may be inaccurate.";
    }
  }

  Color get _color {
    switch (status) {
      case GpsStatus.poorAccuracy:
        return Colors.orange.shade800;
      case GpsStatus.ok:
        return Colors.transparent;
      default:
        return Colors.red.shade800;
    }
  }

  @override
  Widget build(BuildContext context) {
    final message = _message;
    if (message == null) return const SizedBox.shrink();

    return Positioned(
      top: 60,
      left: 12,
      right: 12,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onRetry,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.gps_off, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
