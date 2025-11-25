import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ResumeCacheService {
  static const String _resumeKey = 'cached_resume_json_v1';

  /// Save parsed resume map to persistent storage.
  static Future<void> saveResumeData(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(data);
      await prefs.setString(_resumeKey, encoded);
    } catch (_) {}
  }

  /// Load parsed resume map; returns empty map if missing or invalid.
  static Future<Map<String, dynamic>> loadResumeData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_resumeKey);
      if (raw == null || raw.isEmpty) return {};
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      return {};
    } catch (_) {
      return {};
    }
  }

  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_resumeKey);
    } catch (_) {}
  }
}
