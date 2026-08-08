import 'package:flutter/material.dart';

import 'services/api_service.dart';
import 'services/socket_service.dart';
import 'settings_screen.dart';
import 'player_data.dart';
import 'hide_phase_screen.dart';

class LobbyScreen extends StatefulWidget {
  final String gameCode;

  const LobbyScreen({
    super.key,
    required this.gameCode,
  });

  @override
  State<LobbyScreen> createState() =>
      _LobbyScreenState();
}

class _LobbyScreenState
    extends State<LobbyScreen> {
  List players = [];

  Map settings = {};

  bool isHost = false;

  @override
  void initState() {
    super.initState();

    loadGame();

    SocketService.socket.emit(
      "joinLobby",
      widget.gameCode,
    );

    SocketService.socket.on(
      "lobbyUpdated",
      (data) {
        setState(() {
          players = data["players"];
          settings = data["settings"];

          isHost = players.any(
            (player) =>
                player["name"] ==
                    PlayerData.playerName &&
                player["host"] == true,
          );
        });
      },
    );

    SocketService.socket.on(
      "gameStarted",
      (data) {
        final gameSettings =
            data["settings"];

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                HidePhaseScreen(
              hideMinutes:
                  gameSettings["hideTime"],
            ),
          ),
        );
      },
    );
  }

  Future<void> loadGame() async {
    final game =
        await ApiService.getGame(
      widget.gameCode,
    );

    if (game == null) return;

    setState(() {
      players = game["players"];
      settings = game["settings"];

      isHost = players.any(
        (player) =>
            player["name"] ==
                PlayerData.playerName &&
            player["host"] == true,
      );
    });
  }

  @override
  void dispose() {
    SocketService.socket.off(
      "lobbyUpdated",
    );

    super.dispose();
  }

  Widget settingRow(
    String label,
    dynamic value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 4,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label),
          ),
          Text(
            value.toString(),
          ),
        ],
      ),
    );
  }

  Future<void> openSettings() async {
    final result =
        await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          settings:
              Map<String, dynamic>.from(
            settings,
          ),
        ),
      ),
    );

    if (result == null) return;

    await ApiService.updateSettings(
      widget.gameCode,
      result,
    );

    setState(() {
      settings = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Lobby",
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              "Game Code: ${widget.gameCode}",
              style: const TextStyle(
                fontSize: 26,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Players",
              style: TextStyle(
                fontSize: 24,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              flex: 2,
              child: ListView.builder(
                itemCount: players.length,
                itemBuilder:
                    (context, index) {
                  final player =
                      players[index];

                  return ListTile(
                    title: Text(
                      "${player["host"] ? "👑 " : ""}${player["name"]}",
                    ),
                  );
                },
              ),
            ),

            const Divider(),

            const SizedBox(height: 10),

            const Text(
              "Settings",
              style: TextStyle(
                fontSize: 24,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              flex: 3,
              child: ListView(
                children: [
                  settingRow(
                    "Game Duration",
                    "${settings["gameDuration"] ?? "-"} min",
                  ),
                  settingRow(
                    "Hide Time",
                    "${settings["hideTime"] ?? "-"} min",
                  ),
                  settingRow(
                    "Hunters",
                    settings["hunterCount"] ??
                        "-",
                  ),
                  settingRow(
                    "Zones",
                    settings["zoneCount"] ??
                        "-",
                  ),
                  settingRow(
                    "Start Radius",
                    "${settings["startRadius"] ?? "-"} m",
                  ),
                  settingRow(
                    "Final Radius",
                    "${settings["finalRadius"] ?? "-"} m",
                  ),
                  settingRow(
                    "Zone Wait Time",
                    "${settings["zoneWaitTime"] ?? "-"} min",
                  ),
                  settingRow(
                    "Zone Shrink Time",
                    "${settings["zoneShrinkTime"] ?? "-"} min",
                  ),
                  settingRow(
                    "Red Zone Radius",
                    "${settings["redZoneRadius"] ?? "-"} m",
                  ),
                  settingRow(
                    "Red Zone Shift",
                    "${settings["redZoneShiftTime"] ?? "-"} sec",
                  ),
                ],
              ),
            ),

            if (isHost) ...[
              ElevatedButton(
                onPressed:
                    openSettings,
                child: const Text(
                  "Game Settings",
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              ElevatedButton(
                onPressed: () async {
                  await ApiService.startGame(
                    widget.gameCode,
                  );
                },
                child: const Text(
                  "Start Game",
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}