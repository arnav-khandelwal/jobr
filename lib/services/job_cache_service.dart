import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swipe_app/fake_data/jobs_data.dart';

class JobCacheService {
  static const String _jobsCacheKey = 'cached_jobs_json_v1';
  static const String _viewedIdsKey = 'viewed_job_ids_v1';

  /// Save jobs (from API) to persistent storage.
  static Future<void> saveJobs(List<Job> jobs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = jobs.map((j) => j.toJson()).toList();
      final encoded = jsonEncode(list);
      await prefs.setString(_jobsCacheKey, encoded);
    } catch (e) {
      // Swallow errors silently; caching shouldn't break UX
    }
  }

  /// Load jobs from cache. Returns empty list if none or deserialization fails.
  static Future<List<Job>> loadJobs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_jobsCacheKey);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => Job.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Clear the cached jobs explicitly (optional helper).
  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_jobsCacheKey);
    } catch (_) {}
  }

  /// Persist a viewed job id so it won't be shown again until refresh.
  static Future<void> addViewedJobId(String jobId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getStringList(_viewedIdsKey) ?? [];
      if (!current.contains(jobId)) {
        current.add(jobId);
        await prefs.setStringList(_viewedIdsKey, current);
      }
    } catch (_) {}
  }

  /// Load all viewed job ids.
  static Future<Set<String>> loadViewedJobIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_viewedIdsKey) ?? [];
      return list.toSet();
    } catch (_) {
      return <String>{};
    }
  }

  /// Clear viewed job ids (used on refresh).
  static Future<void> clearViewedJobIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_viewedIdsKey);
    } catch (_) {}
  }
}
