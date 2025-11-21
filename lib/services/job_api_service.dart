import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:swipe_app/fake_data/jobs_data.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class JobApiService {
  static String get baseUrl {
    // Android emulator needs 10.0.2.2 to reach host machine.
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://localhost:8000';
  }

  static Future<List<Job>> fetchJobsFromAPI({
    String searchTerm = 'software developer',
    String location = 'India',
    int pages = 2,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/jobs'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 200));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final jobsData = data['jobs'] as List;

        return jobsData.map((jobJson) => Job.fromJson(jobJson)).toList();
      } else {
        print('API Error: ${response.statusCode}');
        return _getFallbackJobs();
      }
    } catch (e) {
      print('Network Error: $e');
      return _getFallbackJobs();
    }
  }

  static List<Job> _getFallbackJobs() {
    // Return local fake data as fallback
    return availableJobs;
  }

  static Future<bool> isServerHealthy() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/health'))
          .timeout(const Duration(seconds: 100));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
