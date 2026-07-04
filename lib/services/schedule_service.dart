import 'dart:convert';
import '../models/schedule.dart';
import 'api_service.dart';
import 'package:http/http.dart' as http;

class ScheduleService {
  static const String _base = 'https://api.xxsmartsystems.com/api/schedules';

  static Future<Map<String, String>> get _headers async {
    final token = await ApiService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<List<Schedule>> getSchedules() async {
    final res = await http.get(
      Uri.parse(_base),
      headers: await _headers,
    );
    final List data = jsonDecode(res.body);
    return data.map((e) => Schedule.fromJson(e)).toList();
  }

  static Future<List<Schedule>> getDeviceSchedules(String deviceId) async {
    final res = await http.get(
      Uri.parse('$_base/device/$deviceId'),
      headers: await _headers,
    );
    final List data = jsonDecode(res.body);
    return data.map((e) => Schedule.fromJson(e)).toList();
  }

  static Future<Schedule> createSchedule(Schedule schedule) async {
    final res = await http.post(
      Uri.parse(_base),
      headers: await _headers,
      body: jsonEncode(schedule.toJson()),
    );
    return Schedule.fromJson(jsonDecode(res.body));
  }

  static Future<void> deleteSchedule(int id) async {
    await http.delete(
      Uri.parse('$_base/$id'),
      headers: await _headers,
    );
  }

  static Future<void> toggleSchedule(int id) async {
    await http.patch(
      Uri.parse('$_base/$id/toggle'),
      headers: await _headers,
    );
  }
}