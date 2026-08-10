import 'dart:convert';
import 'package:http/http.dart' as http;
import '../player_data.dart';

class ApiService {
  static const String baseUrl = 'http://10.10.0.10:3000';

  static Future<Map<String, dynamic>?> createGame(
    String playerName,
    double lat,
    double lng,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/create-game'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'playerName': playerName, 'lat': lat, 'lng': lng}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data as Map<String, dynamic>;
      }

      return null;
    } catch (e) {
      print("CREATE GAME ERROR");
      print(e);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> joinGame(
    String code,
    String playerName,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/join-game'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'gameCode': code, 'playerName': playerName}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data as Map<String, dynamic>;
      }

      return null;
    } catch (e) {
      print("JOIN GAME ERROR");
      print(e);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getGame(String code) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/game/$code'));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return null;
    } catch (e) {
      print("GET GAME ERROR");
      print(e);
      return null;
    }
  }

  /// Fetches the authoritative game state, including this player's role,
  /// caught status, and the live (possibly mid-shrink) zone radius.
  /// [playerName] is required to resolve "your" role/caught status.
  static Future<Map<String, dynamic>?> getGameState(
    String code,
    String playerName,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/game-state/$code?playerName=$playerName'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return null;
    } catch (e) {
      print("GET GAME STATE ERROR");
      print(e);
      return null;
    }
  }

  static Future<void> updateSettings(String gameCode, String playerId, Map<String, dynamic> settings) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/update-settings'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'gameCode': gameCode, 'settings': settings}),
      );

      print("UPDATE SETTINGS RESPONSE: ${response.statusCode}");
    } catch (e) {
      print("UPDATE SETTINGS ERROR");
      print(e);
    }
  }

  static Future<void> updateZoneCenter(
    String gameCode,
    String playerId,
    double lat,
    double lng,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/update-zone-center'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'gameCode': gameCode,
          'centerLat': lat,
          'centerLng': lng,
        }),
      );

      print("UPDATE ZONE RESPONSE: ${response.statusCode}");
    } catch (e) {
      print("UPDATE ZONE ERROR");
      print(e);
    }
  }

  static Future<void> startGame(String gameCode, String playerId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/start-game'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'gameCode': gameCode, 'playerId': playerId}),
      );

      print("START GAME RESPONSE: ${response.statusCode}");
      print(response.body);
    } catch (e) {
      print("START GAME ERROR");
      print(e);
    }
  }

  static Future<void> updatePosition(
    String gameCode,
    String playerIdentifier,
    double lat,
    double lng,
  ) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/update-position'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'gameCode': gameCode,
          'playerId': PlayerData.playerId,
          'lat': lat,
          'lng': lng,
        }),
      );
    } catch (e) {
      print("UPDATE POSITION ERROR");
      print(e);
    }
  }

  /// Fetches the current player list/positions directly, so a screen that
  /// just loaded doesn't have to wait for the next "positionsUpdated"
  /// socket event to know who else is in the game.
  static Future<List?> getPositions(String gameCode) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/positions/$gameCode'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List;
      }

      return null;
    } catch (e) {
      print("GET POSITIONS ERROR");
      print(e);
      return null;
    }
  }

  /// Marks the calling player (must be a hider) as caught.
  static Future<bool> markCaught(String gameCode, String playerId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/mark-caught'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'gameCode': gameCode, 'playerId': playerId}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("MARK CAUGHT ERROR");
      print(e);
      return false;
    }
  }
}
