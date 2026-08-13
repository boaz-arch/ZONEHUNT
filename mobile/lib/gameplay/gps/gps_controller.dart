import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../../services/api_service.dart';


class _LastSentPosition {
  final DateTime time;
  final Position position;
  const _LastSentPosition(this.time, this.position);
}

class GpsController {
  final String gameCode;
  final String playerId;

  final void Function(Position position) onPositionChanged;

  final void Function(Position initialPosition) onInitialFix;

  StreamSubscription<Position>? _subscription;
  _LastSentPosition? _lastSent;

  GpsController({
    required this.gameCode,
    required this.playerId,
    required this.onPositionChanged,
    required this.onInitialFix,
  });

  Future<void> initialize() async {
    final permission = await requestLocationPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    final position = await Geolocator.getCurrentPosition();

    onInitialFix(position);

    startPositionStream();
  }

  Future<LocationPermission> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission;
  }

  void startPositionStream() {
    _subscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    ).listen((position) {
      onPositionChanged(position);

      if (!shouldSendPosition(position)) return;

      _lastSent = _LastSentPosition(DateTime.now(), position);
      sendPosition(position);
    });
  }

  bool shouldSendPosition(Position position) {
    final now = DateTime.now();

    if (_lastSent != null && now.difference(_lastSent!.time).inSeconds < 1) {
      return false;
    }

    if (_lastSent != null) {
      final movedDistance = Geolocator.distanceBetween(
        _lastSent!.position.latitude,
        _lastSent!.position.longitude,
        position.latitude,
        position.longitude,
      );

      if (movedDistance < 5 &&
          now.difference(_lastSent!.time).inSeconds < 1) {
        return false;
      }
    }

    return true;
  }

  void sendPosition(Position position) {
    ApiService.updatePosition(
      gameCode,
      playerId,
      position.latitude,
      position.longitude,
    );
  }

  void dispose() {
    _subscription?.cancel();
  }
}
