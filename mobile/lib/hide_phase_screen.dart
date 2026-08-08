import 'dart:async';
import 'package:flutter/material.dart';

class HidePhaseScreen
    extends StatefulWidget {
  final int hideMinutes;

  const HidePhaseScreen({
    super.key,
    required this.hideMinutes,
  });

  @override
  State<HidePhaseScreen> createState() =>
      _HidePhaseScreenState();
}

class _HidePhaseScreenState
    extends State<HidePhaseScreen> {
  late int secondsRemaining;

  Timer? timer;

  @override
  void initState() {
    super.initState();

    secondsRemaining =
        widget.hideMinutes * 60;

    timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (secondsRemaining <= 0) {
          timer.cancel();
          return;
        }

        setState(() {
          secondsRemaining--;
        });
      },
    );
  }

  String formatTime() {
    final minutes =
        secondsRemaining ~/ 60;

    final seconds =
        secondsRemaining % 60;

    return "${minutes.toString().padLeft(2, "0")}:${seconds.toString().padLeft(2, "0")}";
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Text(
              "HIDE PHASE",
              style: TextStyle(
                fontSize: 36,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            Text(
              formatTime(),
              style: const TextStyle(
                fontSize: 60,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            const Text(
              "Hiders are hiding.\nHunters wait for the timer.",
              textAlign:
                  TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}