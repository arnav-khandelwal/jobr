import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class PlacementIndiaApplyResult {
  final bool success;
  final String step;
  final String? message;
  PlacementIndiaApplyResult({
    required this.success,
    required this.step,
    this.message,
  });
}

class PlacementIndiaApplyService {
  PlacementIndiaApplyService._();
  static final PlacementIndiaApplyService instance =
      PlacementIndiaApplyService._();

  String get _baseUrl {
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://localhost:8000';
  }

  Future<PlacementIndiaApplyResult> applyJob({
    required String jobUrl,
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/apply/placementindia');
    try {
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'job_url': jobUrl,
          'email': email,
          'password': password,
        }),
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        return PlacementIndiaApplyResult(
          success: data['success'] == true,
          step: (data['step'] ?? 'unknown').toString(),
          message: data['message'] as String?,
        );
      } else {
        return PlacementIndiaApplyResult(
          success: false,
          step: 'http',
          message: 'HTTP ${resp.statusCode}',
        );
      }
    } catch (e) {
      return PlacementIndiaApplyResult(
        success: false,
        step: 'exception',
        message: e.toString(),
      );
    }
  }
}
