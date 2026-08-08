import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      'http://10.10.0.10:3000';

  static Future<String?> createGame(
    String playerName,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/create-game'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'playerName': playerName,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return data['gameCode'];
      }

      return null;
    } catch (e) {
      print(e);
      return null;
    }
  }

  static Future<bool> joinGame(
    String code,
    String playerName,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/join-game'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'gameCode': code,
          'playerName': playerName,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print(e);
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getGame(
    String code,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/game/$code'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return null;
    } catch (e) {
      print(e);
      return null;
    }
  }

  static Future<void> updateSettings(
  String gameCode,
  Map settings,
  ) async {
    await http.post(
      Uri.parse(
        '$baseUrl/update-settings',
      ),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'gameCode': gameCode,
        'settings': settings,
      }),
    );
  }

  static Future<void> startGame(
  String gameCode,
  ) async {
    await http.post(
      Uri.parse(
        '$baseUrl/start-game',
      ),
      headers: {
        'Content-Type':
            'application/json',
      },
      body: jsonEncode({
        'gameCode': gameCode,
      }),
    );
  }
}