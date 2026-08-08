import 'package:flutter/material.dart';

import 'services/api_service.dart';
import 'lobby_screen.dart';
import 'join_screen.dart';
import 'player_data.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const ZoneHuntApp());
}

class ZoneHuntApp extends StatelessWidget {
  const ZoneHuntApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZoneHunt',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState
    extends State<HomeScreen> {
  final nameController =
      TextEditingController();

  Future<void> createGame() async {
    if (nameController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
              Text("Please enter a name"),
        ),
      );
      return;
    }

    PlayerData.playerName =
        nameController.text.trim();

    await Geolocator.requestPermission();

    final position =
        await Geolocator
            .getCurrentPosition();

    final code =
        await ApiService.createGame(
      PlayerData.playerName,
      position.latitude,
      position.longitude,
    );

    if (code == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
              Text("Failed to create game"),
        ),
      );

      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LobbyScreen(
          gameCode: code,
        ),
      ),
    );
  }

  void goToJoinGame() {
    if (nameController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
              Text("Please enter a name"),
        ),
      );
      return;
    }

    PlayerData.playerName =
        nameController.text.trim();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const JoinScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ZoneHunt',
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding:
              const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const Text(
                'ZONEHUNT',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 30,
              ),

              TextField(
                controller:
                    nameController,
                decoration:
                    const InputDecoration(
                  labelText:
                      "Player Name",
                  border:
                      OutlineInputBorder(),
                ),
              ),

              const SizedBox(
                height: 30,
              ),

              SizedBox(
                width: 250,
                height: 60,
                child: ElevatedButton(
                  onPressed:
                      createGame,
                  child: const Text(
                    'Create Game',
                  ),
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              SizedBox(
                width: 250,
                height: 60,
                child: ElevatedButton(
                  onPressed:
                      goToJoinGame,
                  child: const Text(
                    'Join Game',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}