import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'lobby_screen.dart';

class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key});

  @override
  State<JoinScreen> createState() =>
      _JoinScreenState();
}

class _JoinScreenState
    extends State<JoinScreen> {
  final codeController =
      TextEditingController();

  Future<void> joinGame() async {
    final success =
        await ApiService.joinGame(
      codeController.text.toUpperCase(),
      "Boaz",
    );

    if (!success) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Game not found",
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LobbyScreen(
          gameCode:
              codeController.text.toUpperCase(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Join Game"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: codeController,
              decoration:
                  const InputDecoration(
                labelText: "Game Code",
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: joinGame,
              child: const Text("Join"),
            ),
          ],
        ),
      ),
    );
  }
}