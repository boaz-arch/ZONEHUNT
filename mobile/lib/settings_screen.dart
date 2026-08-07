import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  final Map settings;

  const SettingsScreen({
    super.key,
    required this.settings,
  });

  @override
  State<SettingsScreen> createState() =>
      _SettingsScreenState();
}

class _SettingsScreenState
    extends State<SettingsScreen> {

  late TextEditingController gameDuration;
  late TextEditingController hideTime;
  late TextEditingController hunterCount;
  late TextEditingController zoneCount;
  late TextEditingController startRadius;
  late TextEditingController finalRadius;
  late TextEditingController zoneWaitTime;
  late TextEditingController zoneShrinkTime;
  late TextEditingController redZoneRadius;
  late TextEditingController redZoneShiftTime;

  @override
  void initState() {
    super.initState();

    gameDuration = TextEditingController(
      text:
          widget.settings["gameDuration"]
              .toString(),
    );

    hideTime = TextEditingController(
      text:
          widget.settings["hideTime"]
              .toString(),
    );

    hunterCount = TextEditingController(
      text:
          widget.settings["hunterCount"]
              .toString(),
    );

    zoneCount = TextEditingController(
      text:
          widget.settings["zoneCount"]
              .toString(),
    );

    startRadius = TextEditingController(
      text:
          widget.settings["startRadius"]
              .toString(),
    );

    finalRadius = TextEditingController(
      text:
          widget.settings["finalRadius"]
              .toString(),
    );

    zoneWaitTime =
        TextEditingController(
      text:
          widget.settings["zoneWaitTime"]
              .toString(),
    );

    zoneShrinkTime =
        TextEditingController(
      text:
          widget.settings["zoneShrinkTime"]
              .toString(),
    );

    redZoneRadius =
        TextEditingController(
      text:
          widget.settings["redZoneRadius"]
              .toString(),
    );

    redZoneShiftTime =
        TextEditingController(
      text:
          widget.settings[
                  "redZoneShiftTime"]
              .toString(),
    );
  }

  Widget field(
    String label,
    TextEditingController controller,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType:
            TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border:
              const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text("Game Settings"),
      ),
      body: Padding(
        padding:
            const EdgeInsets.all(16),
        child: ListView(
          children: [
            field(
                "Game Duration",
                gameDuration),
            field(
                "Hide Time",
                hideTime),
            field(
                "Hunter Count",
                hunterCount),
            field(
                "Zone Count",
                zoneCount),
            field(
                "Start Radius",
                startRadius),
            field(
                "Final Radius",
                finalRadius),
            field(
                "Zone Wait Time",
                zoneWaitTime),
            field(
                "Zone Shrink Time",
                zoneShrinkTime),
            field(
                "Red Zone Radius",
                redZoneRadius),
            field(
                "Red Zone Shift Time",
                redZoneShiftTime),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  {
                    "gameDuration":
                        int.parse(
                            gameDuration.text),
                    "hideTime":
                        int.parse(
                            hideTime.text),
                    "hunterCount":
                        int.parse(
                            hunterCount.text),
                    "zoneCount":
                        int.parse(
                            zoneCount.text),
                    "startRadius":
                        int.parse(
                            startRadius.text),
                    "finalRadius":
                        int.parse(
                            finalRadius.text),
                    "zoneWaitTime":
                        int.parse(
                            zoneWaitTime.text),
                    "zoneShrinkTime":
                        int.parse(
                            zoneShrinkTime.text),
                    "redZoneRadius":
                        int.parse(
                            redZoneRadius.text),
                    "redZoneShiftTime":
                        int.parse(
                            redZoneShiftTime
                                .text),
                  },
                );
              },
              child:
                  const Text("Save"),
            )
          ],
        ),
      ),
    );
  }
}