import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'services/socket_service.dart';

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
        });
      },
    );
  }

  Future<void> loadGame() async {
    final game =
        await ApiService.getGame(widget.gameCode);

    if (game == null) return;

    setState(() {
      players = game["players"];
    });
  }

  @override
  void dispose() {
    SocketService.socket.off("lobbyUpdated");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lobby"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              "Game Code: ${widget.gameCode}",
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              "Players",
              style: TextStyle(
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: players.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                      players[index]["name"],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}