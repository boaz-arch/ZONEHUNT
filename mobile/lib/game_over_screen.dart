import 'package:flutter/material.dart';
import 'session.dart';
import 'home_screen.dart';

class GameOverScreen extends StatelessWidget {
  final String winner; // "hunters" | "hiders"
  final String role;

  const GameOverScreen({
    super.key,
    required this.winner,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final youWon = (winner == "hunters" && role == "hunter") ||
        (winner == "hiders" && role == "hider");

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                youWon ? "VICTORY" : "DEFEAT",
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: youWon ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                winner == "hunters"
                    ? "The hunters caught everyone!"
                    : "The hiders survived the clock!",
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: 220,
                height: 55,
                child: ElevatedButton(
                  onPressed: () async {
                    await clearSession();

                    if (!context.mounted) return;

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                      (route) => false,
                    );
                  },
                  child: const Text("Back to Home"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}