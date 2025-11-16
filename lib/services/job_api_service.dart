import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:swipe_app/fake_data/jobs_data.dart';

class JobApiService {
  static const String baseUrl =
      'http://192.168.1.3:8000'; // Change for production

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
          .timeout(const Duration(seconds: 10));

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
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
