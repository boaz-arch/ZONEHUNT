import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'services/api_service.dart';
import 'services/socket_service.dart';
import 'settings_screen.dart';
import 'player_data.dart';
import 'hide_phase_screen.dart';
import 'zone_picker_screen.dart';
import 'full_map_screen.dart';

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

  final MapController mapController =
    MapController();


  List players = [];

  Map settings = {};

  bool isHost = false;

  double centerLat = 31.7683;
  double centerLng = 35.2137;

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

          if (data["zone"] != null) {
            centerLat =
                data["zone"]["centerLat"];
            centerLng =
                data["zone"]["centerLng"];
          }

          mapController.move(
            LatLng(
              centerLat,
              centerLng,
            ),
            mapController.camera.zoom,
          );

          isHost = players.any(
            (player) =>
                player["id"] ==
                    PlayerData.playerId &&
                player["host"] == true,
          );
        });
      },
    );

    SocketService.socket.on(
      "gameStarted",
      (data) {

        final myPlayer =
            (data["players"] as List)
                .firstWhere(
          (player) =>
              player["id"] ==
              PlayerData.playerId,
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
              HidePhaseScreen(
                gameCode: widget.gameCode,
                hidePhaseEndsAt: data["hidePhaseEndsAt"],
                role: myPlayer["role"],
                centerLat: data["zone"]["centerLat"],
                centerLng: data["zone"]["centerLng"],
                radius: (data["settings"]["startRadius"])
                    .toDouble(),

                anonymousMode: data["settings"]["anonymousMode"]
                  ?? false,
              )
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

      if (game["zone"] != null) {
        centerLat =
            game["zone"]["centerLat"];

        centerLng =
            game["zone"]["centerLng"];
      }

      isHost = players.any(
        (player) =>
            player["id"] ==
                PlayerData.playerId &&
            player["host"] == true,
      );
    });

  WidgetsBinding.instance
      .addPostFrameCallback((_) {

    mapController.move(
      LatLng(
        centerLat,
        centerLng,
      ),
      14,
    );

  });
}

  @override
  void dispose() {
    SocketService.socket.off(
      "lobbyUpdated",
    );

    SocketService.socket.off(
      "gameStarted",
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
      PlayerData.playerId,
      result,
    );

    setState(() {
      settings = result;
    });
  }

  Future<void> selectZone() async {
    final result =
        await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
          ZonePickerScreen(
            centerLat: centerLat,
            centerLng: centerLng,
          ),
      ),
    );

    if (result == null) return;

    await ApiService.updateZoneCenter(
      widget.gameCode,
      PlayerData.playerId,
      result.latitude,
      result.longitude,
    );
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
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              "Game Code: ${widget.gameCode}",
              textAlign: TextAlign.center,
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
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            ...players.map(
              (player) => ListTile(
                dense: true,
                title: Text(
                  "${player["host"] ? "👑 " : ""}${player["name"]}",
                ),
              ),
            ),

            const Divider(),

            const Text(
              "Map Preview",
              style: TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              height: 250,
              child: FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  initialCenter: LatLng(
                    centerLat,
                    centerLng,
                  ),
                  initialZoom: 14,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  ),

                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: LatLng(
                          centerLat,
                          centerLng,
                        ),
                        radius:
                            settings[
                                    "startRadius"] ??
                                1000,
                        useRadiusInMeter:
                            true,
                        color: Colors.blue
                            .withOpacity(
                                0.20),
                        borderColor:
                            Colors.blue,
                        borderStrokeWidth:
                            3,
                      ),
                    ],
                  ),
                ],
              ),
            ),


            const SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FullMapScreen(
                      centerLat: centerLat,
                      centerLng: centerLng,
                      radius:
                          settings["startRadius"] ??
                              1000,
                    ),
                  ),
                );
              },
              icon: const Icon(
                Icons.fullscreen,
              ),
              label: const Text(
                "Expand Map",
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Settings",
              style: TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

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
              "Zone Wait",
              "${settings["zoneWaitTime"] ?? "-"} min",
            ),

            settingRow(
              "Zone Shrink",
              "${settings["zoneShrinkTime"] ?? "-"} min",
            ),

            settingRow(
              "Red Radius",
              "${settings["redZoneRadius"] ?? "-"} m",
            ),

            settingRow(
              "Red Shift",
              "${settings["redZoneShiftTime"] ?? "-"} sec",
            ),

            settingRow(
              "Anonymous Mode",
              settings["anonymousMode"] ==
                      true
                  ? "ON"
                  : "OFF",
            ),

            settingRow(
              "Random Future Zones",
              settings["randomFutureZones"] ==
                      true
                  ? "ON"
                  : "OFF",
            ),

            const SizedBox(height: 20),

            if (isHost) ...[
              ElevatedButton(
                onPressed:
                    selectZone,
                child: const Text(
                  "Select First Zone",
                ),
              ),

              const SizedBox(height: 10),

              ElevatedButton(
                onPressed:
                    openSettings,
                child: const Text(
                  "Game Settings",
                ),
              ),

              const SizedBox(height: 10),

              ElevatedButton(
                onPressed: () async {
                  await ApiService.startGame(
                    widget.gameCode,
                    PlayerData.playerId,
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