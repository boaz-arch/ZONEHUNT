import 'package:flutter/material.dart';

import '../models/player.dart';

class RemainingHidersPanel extends StatelessWidget {
  final int remainingHiders;
  final bool showPlayerList;
  final VoidCallback onToggle;
  final List<Player> hiders;
  final List<Player> hunters;
  final Map<String, int> playerNumbers;

  const RemainingHidersPanel({
    super.key,
    required this.remainingHiders,
    required this.showPlayerList,
    required this.onToggle,
    required this.hiders,
    required this.hunters,
    required this.playerNumbers,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 10,
      top: 10,
      child: Container(
        constraints: const BoxConstraints(minWidth: 140),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "REMAINING: $remainingHiders",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    showPlayerList
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.white,
                  ),
                  onPressed: onToggle,
                ),
              ],
            ),
            if (showPlayerList) ...[
              const Divider(color: Colors.white30),
              const SizedBox(height: 8),
              const Text(
                "Hiders:",
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              ..._buildRoster(hiders),
              const SizedBox(height: 12),
              const Text(
                "Hunters:",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              ..._buildRoster(hunters),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRoster(List<Player> players) {
    return players.map((player) {
      final number = playerNumbers[player.id];
      return Text(
        "$number. ${player.name}",
        style: TextStyle(
          color: player.caught ? Colors.grey : Colors.white,
        ),
      );
    }).toList();
  }
}
