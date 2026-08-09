import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'lobby_screen.dart';
import 'player_data.dart';
import 'session.dart';

class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key});

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  final codeController = TextEditingController();

  bool joining = false;

  Future<void> joinGame() async {
    final code = codeController.text.toUpperCase();

    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a game code")),
      );
      return;
    }

    setState(() => joining = true);

    final success = await ApiService.joinGame(code, PlayerData.playerName);

    setState(() => joining = false);

    if (!success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Game not found")),
      );
      return;
    }

    await saveSession(code, PlayerData.playerName);

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LobbyScreen(gameCode: code)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Join Game")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: codeController,
              decoration: const InputDecoration(labelText: "Game Code"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: joining ? null : joinGame,
              child: joining
                  ? const CircularProgressIndicator()
                  : const Text("Join"),
            ),
          ],
        ),
      ),
    );
  }
}