import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:swipe_app/fake_data/jobs_data.dart';
import 'package:swipe_app/services/resume_cache_service.dart';
import 'package:swipe_app/services/job_cache_service.dart';

class RecommendationsService {
  RecommendationsService._();
  static final RecommendationsService instance = RecommendationsService._();

  // Base URL handling for different platforms (match AuthService)
  String get _baseUrl {
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://localhost:8000';
  }

  Future<List<Job>> fetchRecommendedJobs({
    Map<String, dynamic>? resume,
    List<Job>? jobs,
    int maxRecommendations = 5,
  }) async {
    // Allow callers to pass resume and jobs directly (avoid double-loading);
    // otherwise fall back to cached values.
    final resumeData = resume ?? await ResumeCacheService.loadResumeData();
    final jobsList = jobs ?? await JobCacheService.loadJobs();
    if (resumeData.isEmpty || jobsList.isEmpty) return [];

    // Limit jobs sent to backend to avoid huge prompt
    final subset = jobsList.take(50).toList();

    final body = jsonEncode({
      'resume_data': resumeData,
      'jobs': subset.map((j) => j.toJson()).toList(),
      'max_recommendations': maxRecommendations,
    });

    final uri = Uri.parse('$_baseUrl/api/recommendations');
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (resp.statusCode != 200) {
      return [];
    }
    final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
    final list = decoded['jobs'] as List<dynamic>?;
    if (list == null) return [];
    return list.map((e) => Job.fromJson(e as Map<String, dynamic>)).toList();
  }
}
