import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swipe_app/fake_data/jobs_data.dart';

class ApplicationRecord {
  final String id;
  final String jobId;
  final String jobTitle;
  final String companyName;
  final String source;
  final String status;
  final DateTime appliedAt;
  final Job jobSnapshot; // constructed from embedded fields

  ApplicationRecord({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.companyName,
    required this.source,
    required this.status,
    required this.appliedAt,
    required this.jobSnapshot,
  });

  static ApplicationRecord fromJson(Map<String, dynamic> json) {
    // Build a Job object from embedded snapshot (fields may be partial)
    final job = Job(
      jobId: json['job_id'] ?? json['jobId'] ?? '',
      jobTitle: json['job_title'] ?? json['jobTitle'] ?? '',
      companyName: json['company_name'] ?? json['companyName'] ?? '',
      location: json['location'] ?? '',
      jobType: json['job_type'] ?? '',
      salary: json['salary'] ?? '',
      experienceRequired: json['experience_required'] ?? '',
      skills:
          (json['skills'] as List?)?.map((e) => e.toString()).toList() ?? [],
      jobDescription: '',
      postedDate: '',
      applyLink: json['apply_link'] ?? '',
      source: json['source'] ?? '',
      remoteFriendly: false,
      companyLogoUrl: null,
      industry: null,
      educationRequired: null,
    );
    return ApplicationRecord(
      id: json['id'],
      jobId: job.jobId,
      jobTitle: job.jobTitle,
      companyName: job.companyName,
      source: job.source,
      status: json['status'] ?? 'applied',
      appliedAt: DateTime.tryParse(json['applied_at'] ?? '') ?? DateTime.now(),
      jobSnapshot: job,
    );
  }
}

class ApplicationsService {
  ApplicationsService._();
  static final ApplicationsService instance = ApplicationsService._();

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<String> _baseUrl() async {
    // Android emulator cannot reach host 'localhost' of dev machine; use 10.0.2.2.
    // iOS simulator supports localhost directly. For physical devices, consider
    // replacing with your machine's LAN IP and ensure firewall allows inbound.
    final host = Platform.isAndroid ? '10.0.2.2' : 'localhost';
    return 'http://$host:8000';
  }

  Future<ApplicationRecord?> createApplication(Job job) async {
    final token = await _getToken();
    if (token == null) return null; // require auth
    final base = await _baseUrl();
    final url = Uri.parse('$base/api/applications/');
    final body = jsonEncode({
      'job_id': job.jobId,
      'job_title': job.jobTitle,
      'company_name': job.companyName,
      'source': job.source,
      'apply_link': job.applyLink,
      'location': job.location,
      'job_type': job.jobType,
      'salary': job.salary,
      'experience_required': job.experienceRequired,
      'skills': job.skills,
    });
    try {
      final resp = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );
      if (resp.statusCode == 201 || resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        return ApplicationRecord.fromJson(data);
      } else {
        debugPrint('createApplication failed: ${resp.statusCode} ${resp.body}');
      }
    } on SocketException catch (e) {
      debugPrint('Network error creating application: $e');
    } catch (e) {
      debugPrint('Unexpected error creating application: $e');
    }
    return null;
  }

  Future<List<ApplicationRecord>> fetchApplications() async {
    final token = await _getToken();
    if (token == null) return [];
    final base = await _baseUrl();
    final url = Uri.parse('$base/api/applications/');
    try {
      final resp = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as List<dynamic>;
        return data
            .map((e) => ApplicationRecord.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        debugPrint('fetchApplications failed: ${resp.statusCode} ${resp.body}');
      }
    } on SocketException catch (e) {
      debugPrint('Network error fetching applications: $e');
    } catch (e) {
      debugPrint('Unexpected error fetching applications: $e');
    }
    return [];
  }
}
