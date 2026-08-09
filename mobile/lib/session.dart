import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/api_service.dart';
import 'player_data.dart';
import 'home_screen.dart';
import 'lobby_screen.dart';
import 'hide_phase_screen.dart';
import 'gameplay_screen.dart';

const _codeKey = 'activeGameCode';
const _nameKey = 'activePlayerName';

Future<void> saveSession(String gameCode, String playerName) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_codeKey, gameCode);
  await prefs.setString(_nameKey, playerName);
}

Future<void> clearSession() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_codeKey);
  await prefs.remove(_nameKey);
}

/// Checks for a saved game session and, if one exists and the game is
/// still live on the server, rebuilds the correct screen for whatever
/// phase the game is currently in (lobby / hide / gameplay). Falls back
/// to the home screen if there's no session or the game has ended.
Future<Widget> resolveStartScreen() async {
  final prefs = await SharedPreferences.getInstance();
  final code = prefs.getString(_codeKey);
  final name = prefs.getString(_nameKey);

  if (code == null || name == null) {
    return const HomeScreen();
  }

  PlayerData.playerName = name;

  final state = await ApiService.getGameState(code, name);

  if (state == null || state["phase"] == "ended" || state["phase"] == null) {
    await clearSession();
    return const HomeScreen();
  }

  final settings = Map<String, dynamic>.from(state["settings"] ?? {});
  final zone = Map<String, dynamic>.from(state["zone"] ?? {});
  final role = state["role"] as String? ?? "hider";
  final anonymousMode = settings["anonymousMode"] == true;

  switch (state["phase"]) {
    case "lobby":
      return LobbyScreen(gameCode: code);

    case "hide":
      return HidePhaseScreen(
        gameCode: code,
        hidePhaseEndsAt: state["hidePhaseEndsAt"] as int,
        role: role,
        centerLat: (zone["centerLat"] as num).toDouble(),
        centerLng: (zone["centerLng"] as num).toDouble(),
        radius: (zone["radius"] as num).toDouble(),
        anonymousMode: anonymousMode,
      );

    case "gameplay":
      return GameplayScreen(
        gameCode: code,
        role: role,
        centerLat: (zone["centerLat"] as num).toDouble(),
        centerLng: (zone["centerLng"] as num).toDouble(),
        radius: (zone["radius"] as num).toDouble(),
        anonymousMode: anonymousMode,
      );

    default:
      await clearSession();
      return const HomeScreen();
  }
}