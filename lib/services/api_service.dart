import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://api.xxsmartsystems.com';

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  static Future<Map> register(String email, String password, {String name = ''}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password, 'name': name}),
    );
    return jsonDecode(res.body);
  }

  static Future<Map> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return jsonDecode(res.body);
  }

  static Future<List> getDevices() async {
    final token = await getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/api/devices'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(res.body);
  }

  static Future<Map> addDevice(String name, String boardType, {
    String description = '',
    String icon = '📡',
    String color = '#00D4FF',
  }) async {
    final token = await getToken();
    final res = await http.post(
      Uri.parse('$baseUrl/api/devices'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'board_type': boardType,
        'description': description,
        'icon': icon,
        'color': color,
      }),
    );
    return jsonDecode(res.body);
  }

  static Future<Map> sendCommand(String topic, String command) async {
    final token = await getToken();
    final res = await http.post(
      Uri.parse('$baseUrl/api/commands/send'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'topic': topic, 'command': command}),
    );
    return jsonDecode(res.body);
  }

  static Future<void> saveWidgets(String deviceId, List widgets) async {
    final token = await getToken();
    await http.put(
      Uri.parse('$baseUrl/api/devices/$deviceId/widgets'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'widgets': widgets}),
    );
  }

  static Future<List> loadWidgets(String deviceId) async {
    final token = await getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/api/devices/$deviceId/widgets'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(res.body);
  }

  static Future<void> saveWidgetState(String deviceId, int widgetIndex, Map<String, dynamic> state) async {
    final token = await getToken();
    await http.patch(
      Uri.parse('$baseUrl/api/devices/$deviceId/widgets/$widgetIndex/state'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'state': state}),
    );
  }

  static Future<void> savePin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('credentials_pin', pin);
  }

  static Future<String?> getPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('credentials_pin');
  }

  static Future<void> deleteDevice(String deviceId) async {
    final token = await getToken();
    await http.delete(
      Uri.parse('$baseUrl/api/devices/$deviceId'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  static Future<Map> sendResetCode(String email) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    return jsonDecode(res.body);
  }

  static Future<Map> verifyResetCode(String email, String code) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/verify-reset-code'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code}),
    );
    return jsonDecode(res.body);
  }

  static Future<Map> resetPassword(String email, String code, String newPassword) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code, 'password': newPassword}),
    );
    return jsonDecode(res.body);
  }

  static Future<Map> getProfile() async {
    final token = await getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/api/auth/profile'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(res.body);
  }

  static Future<Map> verifyEmail(String email, String code) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/verify-email'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code}),
    );
    return jsonDecode(res.body);
  }

  static Future<List> getChatMessages() async {
    final token = await getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/api/chat/messages'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(res.body);
  }

  static Future<Map> sendChatMessage(String message) async {
    final token = await getToken();
    final res = await http.post(
      Uri.parse('$baseUrl/api/chat/send'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'message': message}),
    );
    return jsonDecode(res.body);
  }

  static Future<Map?> getLatestAnnouncement() async {
    final token = await getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/api/announcements/latest'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final body = jsonDecode(res.body);
    if (body == null || body is! Map) return null;
    return body;
  }

  static Future<Map> submitWidgetSuggestion(String widgetName, String useCase) async {
    final token = await getToken();
    final res = await http.post(
      Uri.parse('$baseUrl/api/suggestions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'widget_name': widgetName, 'use_case': useCase}),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>?> getAiInsights() async {
    try {
      final token = await getToken();
      if (token == null) return null;
      final res = await http.get(
        Uri.parse('$baseUrl/api/ai/insights'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> createScheduleFromBot({
    required String deviceId,
    required String widgetLabel,
    required String mqttTopic,
    required String command,
    required DateTime scheduledAt,
  }) async {
    try {
      final token = await getToken();
      final res = await http.post(
        Uri.parse('$baseUrl/api/schedules'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({
          'device_id': deviceId,
          'widget_id': 'xxbot_auto',
          'widget_label': widgetLabel,
          'mqtt_topic': mqttTopic,
          'command': command,
          'scheduled_at': scheduledAt.toIso8601String(),
          'is_recurring': true,
          'repeat_days': [0,1,2,3,4,5,6],
        }),
      );
      return res.statusCode == 200;
    } catch (_) { return false; }
  }

  static Future<Map<String, dynamic>> askXxBot(String message) async {
    try {
      final token = await getToken();
      if (token == null) return {'reply': null, 'action': null};
      final res = await http.post(
        Uri.parse('$baseUrl/api/ai/chat'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'message': message}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final reply = data['reply'] as String? ?? '';
        try {
          final cleaned = reply
              .replaceAll('```json', '')
              .replaceAll('```', '')
              .trim();
          if (cleaned.startsWith('{')) {
            final parsed = jsonDecode(cleaned);
            if (parsed['action'] == 'schedule') {
              return {'reply': null, 'action': parsed};
            }
          }
        } catch (_) {}
        return {'reply': reply, 'action': null};
      }
      return {'reply': null, 'action': null};
    } catch (_) {
      return {'reply': null, 'action': null};
    }
  }
  static Future<Map> resendVerification(String email) async {
  final res = await http.post(
    Uri.parse('$baseUrl/api/auth/resend-verification'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email}),
  );
  return jsonDecode(res.body);
}

}
