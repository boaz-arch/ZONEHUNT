import 'dart:async';
 
import 'package:geolocator/geolocator.dart';
 
import '../../services/api_service.dart';
import 'gps_status.dart';
 
 
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
  
  final void Function( GpsStatus status ) onStatusChanged;

  Timer? _permissionCheckTimer;

  StreamSubscription<Position>? _subscription;

  _LastSentPosition? _lastSent;

  Position? _lastReceivedPosition;
  DateTime? _lastPositionTime;
 
  GpsController({
    required this.gameCode,
    required this.playerId,
    required this.onPositionChanged,
    required this.onInitialFix,
    required this.onStatusChanged,
  });
 
  Future<void> initialize() async {
    final serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      onStatusChanged(
        GpsStatus.disabled,
      );

      return;
    }

    final permission = 
        await requestLocationPermission();
 
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }
 
    final position = await Geolocator.getCurrentPosition();
 
    onInitialFix(position);
 
    startPositionStream();
    startPermissionMonitoring();
  }
 
  Future<LocationPermission> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
 
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
 
    return permission;
  }

  bool looksLikeTeleport(
    Position position,
  ) {

    if (
      _lastReceivedPosition == null ||
      _lastPositionTime == null
    ) {
      return false;
    }

    final distance =
        Geolocator.distanceBetween(
      _lastReceivedPosition!.latitude,
      _lastReceivedPosition!.longitude,
      position.latitude,
      position.longitude,
    );

    final elapsedSeconds =
        DateTime.now()
            .difference(
              _lastPositionTime!,
            )
            .inSeconds;

    if (elapsedSeconds <= 0) {
      return false;
    }

    final speedMetersPerSecond =
        distance / elapsedSeconds;

    return speedMetersPerSecond > 50;
  }



  void startPermissionMonitoring() {
    _permissionCheckTimer =
        Timer.periodic(
      const Duration(seconds: 3),
      (_) async {

        final permission =
            await Geolocator.checkPermission();

        if (
            permission ==
                LocationPermission.denied) {

          onStatusChanged(
            GpsStatus.permissionDenied,
          );

        } else if (
            permission ==
                LocationPermission.deniedForever) {

          onStatusChanged(
            GpsStatus.permissionDeniedForever,
          );

        }
      },
    );
  }
 
  void startPositionStream() {
    _subscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    ).listen(
      (position) {
        if (position.accuracy > 50) {
          onStatusChanged(
            GpsStatus.poorAccuracy,
          );
        } else {
          onStatusChanged(
            GpsStatus.ok,
          );
        }

        if (looksLikeTeleport(position)) {
          return;
        }

        _lastReceivedPosition = position;
        
        _lastPositionTime = DateTime.now();

        onPositionChanged(position);

        // Temporarily comment out

        // if (position.accuracy > 100) {
        //   return;
        // }

        if (!shouldSendPosition(position)) {
          return;
        }

        _lastSent = _LastSentPosition(
          DateTime.now(),
          position,
        );

        sendPosition(position);
      },
      onError: (_) {

        onStatusChanged(
          GpsStatus.signalLost,
        );

      },
    );
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
    _permissionCheckTimer?.cancel();
  }
}
 