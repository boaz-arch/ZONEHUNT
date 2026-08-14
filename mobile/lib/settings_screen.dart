import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  final Map settings;
  final int playerCount;

  const SettingsScreen({
    super.key,
    required this.settings,
    required this.playerCount,
  });

  @override
  State<SettingsScreen> createState() =>
      _SettingsScreenState();
}

class _SettingsScreenState
    extends State<SettingsScreen> {
  late double gameDuration;
  late double hideTime;
  late double hunterCount;
  late double zoneCount;

  late double startRadius;
  late double finalRadius;

  late double zoneWaitTime;
  late double zoneShrinkTime;

  late double redZoneRadius;
  late double redZoneShiftTime;

  bool anonymousMode = false;
  bool randomFutureZones = true;

  late double outsideZoneTime;

  @override
  void initState() {
    super.initState();

    gameDuration =
        (widget.settings["gameDuration"] ?? 60)
            .toDouble();

    hideTime =
        (widget.settings["hideTime"] ?? 5)
            .toDouble();

    hunterCount =
        (widget.settings["hunterCount"] ?? 2)
            .toDouble();

    zoneCount =
        (widget.settings["zoneCount"] ?? 5)
            .toDouble();

    startRadius =
        (widget.settings["startRadius"] ?? 1000)
            .toDouble();

    finalRadius =
        (widget.settings["finalRadius"] ?? 100)
            .toDouble();

    zoneWaitTime =
        (widget.settings["zoneWaitTime"] ?? 5)
            .toDouble();

    zoneShrinkTime =
        (widget.settings["zoneShrinkTime"] ?? 3)
            .toDouble();

    redZoneRadius =
        (widget.settings["redZoneRadius"] ?? 50)
            .toDouble();

    redZoneShiftTime =
        (widget.settings["redZoneShiftTime"] ?? 120)
            .toDouble();

    anonymousMode =
        widget.settings["anonymousMode"] ??
            false;

    randomFutureZones =
        widget.settings[
                "randomFutureZones"] ??
            true;

    outsideZoneTime =
        (widget.settings["outsideZoneTime"] ?? 10)
            .toDouble();
  }

  Widget buildSlider({
    required String title,
    required double value,
    required double min,
    required double max,
    required String suffix,
    required ValueChanged<double>
        onChanged,
  }) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              "$title: ${value.round()}$suffix",
              style: const TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            Slider(
              value: value,
              min: min,
              max: max,
              divisions: (max - min).round() <= 0
                  ? 1
                  : (max - min).round(),
              onChanged: max == min
                  ? null
                  : onChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget zonePreview() {
    final zones = zoneCount.round();

    final radii = <double>[];

    if (zones == 1) {
      radii.add(startRadius);
    } else {
      for (int i = 0;
          i < zones;
          i++) {
        final ratio =
            i / (zones - 1);

        final radius =
            startRadius -
                ((startRadius -
                        finalRadius) *
                    ratio);

        radii.add(radius);
      }
    }

    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              "Zone Size Preview",
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            ...List.generate(
              radii.length,
              (index) => Text(
                "Zone ${index + 1} → ${radii[index].round()}m",
              ),
            ),
          ],
        ),
      ),
    );
  }

  int estimatedGameLength() {
    return hideTime.round() +
        (zoneWaitTime.round() *
            zoneCount.round()) +
        (zoneShrinkTime.round() *
            zoneCount.round());
  }

  @override
  Widget build(BuildContext context) {
    final estimatedDuration =
        estimatedGameLength();

    final maxHunters =
        widget.playerCount <= 1
            ? 1.0
            : (widget.playerCount - 1)
                .toDouble();
    
    return Scaffold(
      appBar: AppBar(
        title:
            const Text("Game Settings"),
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(12),
        children: [
          buildSlider(
            title: "Game Duration",
            value: gameDuration,
            min: 5,
            max: 120,
            suffix: " min",
            onChanged: (v) {
              setState(() {
                gameDuration = v;
              });
            },
          ),

          buildSlider(
            title: "Hide Time",
            value: hideTime,
            min: 0,
            max: 30,
            suffix: " min",
            onChanged: (v) {
              setState(() {
                hideTime = v;
              });
            },
          ),

          buildSlider(
            title: "Hunters",
            value: hunterCount,
            min: 1,
            max: maxHunters,
            suffix: "",
            onChanged: (v) {
              setState(() {
                hunterCount = v;
              });
            },
          ),


          buildSlider(
            title: "Outside Zone Time",
            value: outsideZoneTime,
            min: 0,
            max: 120,
            suffix: " sec",
            onChanged: (v) {
              setState(() {
                outsideZoneTime = v;
              });
            },
          ),

          buildSlider(
            title: "Zone Count",
            value: zoneCount,
            min: 1,
            max: 20,
            suffix: "",
            onChanged: (v) {
              setState(() {
                zoneCount = v;
              });
            },
          ),

          buildSlider(
            title: "Starting Radius",
            value: startRadius,
            min: 50,
            max: 5000,
            suffix: " m",
            onChanged: (v) {
              setState(() {
                startRadius = v;
              });
            },
          ),

          buildSlider(
            title: "Final Radius",
            value: finalRadius,
            min: 10,
            max: 500,
            suffix: " m",
            onChanged: (v) {
              setState(() {
                finalRadius = v;
              });
            },
          ),

          buildSlider(
            title: "Zone Wait Time",
            value: zoneWaitTime,
            min: 1,
            max: 30,
            suffix: " min",
            onChanged: (v) {
              setState(() {
                zoneWaitTime = v;
              });
            },
          ),

          buildSlider(
            title: "Zone Shrink Time",
            value: zoneShrinkTime,
            min: 1,
            max: 20,
            suffix: " min",
            onChanged: (v) {
              setState(() {
                zoneShrinkTime = v;
              });
            },
          ),

          buildSlider(
            title: "Red Zone Radius",
            value: redZoneRadius,
            min: 10,
            max: 1000,
            suffix: " m",
            onChanged: (v) {
              setState(() {
                redZoneRadius = v;
              });
            },
          ),

          buildSlider(
            title: "Red Zone Shift",
            value: redZoneShiftTime,
            min: 15,
            max: 300,
            suffix: " sec",
            onChanged: (v) {
              setState(() {
                redZoneShiftTime = v;
              });
            },
          ),

          SwitchListTile(
            title:
                const Text("Anonymous Mode"),
            subtitle: const Text(
              "Names visible in lobby, hidden during game",
            ),
            value: anonymousMode,
            onChanged: (v) {
              setState(() {
                anonymousMode = v;
              });
            },
          ),

          SwitchListTile(
            title: const Text(
              "Random Future Zones",
            ),
            value: randomFutureZones,
            onChanged: (v) {
              setState(() {
                randomFutureZones = v;
              });
            },
          ),

          zonePreview(),

          Card(
            color:
                estimatedDuration >
                        gameDuration
                            .round()
                    ? Colors.red.shade700
                    : Colors.green
                        .shade700,
            child: Padding(
              padding:
                  const EdgeInsets.all(
                      12),
              child: Text(
                "Estimated Match Length: $estimatedDuration minutes",
              ),
            ),
          ),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: () {
              Navigator.pop(
                context,
                {
                  "gameDuration":
                      gameDuration.round(),
                  "hideTime":
                      hideTime.round(),
                  "hunterCount":
                      hunterCount.round(),
                  "zoneCount":
                      zoneCount.round(),
                  "startRadius":
                      startRadius.round(),
                  "finalRadius":
                      finalRadius.round(),
                  "zoneWaitTime":
                      zoneWaitTime.round(),
                  "zoneShrinkTime":
                      zoneShrinkTime.round(),
                  "redZoneRadius":
                      redZoneRadius.round(),
                  "redZoneShiftTime":
                      redZoneShiftTime.round(),
                  "anonymousMode":
                      anonymousMode,
                  "randomFutureZones":
                      randomFutureZones,
                  "outsideZoneTime":
                      outsideZoneTime.round(),
                },
              );
            },
            child:
                const Text("Save"),
          ),
        ],
      ),
    );
  }
}