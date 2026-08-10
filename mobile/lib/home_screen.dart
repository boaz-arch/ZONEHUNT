import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'services/api_service.dart';
import 'lobby_screen.dart';
import 'join_screen.dart';
import 'player_data.dart';
import 'session.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final nameController = TextEditingController();

  bool creating = false;

  Future<void> createGame() async {
    if (nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a name")),
      );
      return;
    }

    setState(() => creating = true);

    PlayerData.playerName = nameController.text.trim();

    await Geolocator.requestPermission();
    final position = await Geolocator.getCurrentPosition();

    final result = await ApiService.createGame(
      PlayerData.playerName,
      position.latitude,
      position.longitude,
    );

    final code = result?["gameCode"];
    final playerId = result?["playerId"] ?? "";
    PlayerData.playerId = playerId;

    setState(() => creating = false);

    if (code == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to create game")),
      );
      return;
    }

    await saveSession(
      code,
      PlayerData.playerName,
      playerId,
    );

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LobbyScreen(gameCode: code)),
    );
  }

  void goToJoinGame() {
    if (nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a name")),
      );
      return;
    }

    PlayerData.playerName = nameController.text.trim();

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const JoinScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ZoneHunt'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'ZONEHUNT',
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Player Name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: 250,
                height: 60,
                child: ElevatedButton(
                  onPressed: creating ? null : createGame,
                  child: creating
                      ? const CircularProgressIndicator()
                      : const Text('Create Game'),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 250,
                height: 60,
                child: ElevatedButton(
                  onPressed: goToJoinGame,
                  child: const Text('Join Game'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}