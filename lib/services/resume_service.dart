import 'dart:io' show File, Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';

class ResumeService {
  ResumeService._();
  static final ResumeService instance = ResumeService._();

  String get _baseUrl {
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://localhost:8000';
  }

  Uri get _parseUri => Uri.parse('$_baseUrl/parse-resume');

  /// Uploads a resume PDF (File on mobile/desktop, bytes on web) and returns parsed JSON map.
  Future<Map<String, dynamic>> parseResume({
    File? file,
    List<int>? bytes,
    String? fileName,
  }) async {
    if (file == null && bytes == null) {
      throw ResumeException('No file data provided');
    }

    final request = http.MultipartRequest('POST', _parseUri);

    if (kIsWeb) {
      if (bytes == null) throw ResumeException('Missing bytes for web upload');
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName ?? 'resume.pdf',
          contentType: MediaType('application', 'pdf'),
        ),
      );
    } else {
      final f = file!;
      final stream = http.ByteStream(f.openRead());
      final length = await f.length();
      request.files.add(
        http.MultipartFile(
          'file',
          stream,
          length,
          filename: fileName ?? f.path.split('/').last,
          contentType: MediaType('application', 'pdf'),
        ),
      );
    }

    final response = await request.send();
    final body = await response.stream.bytesToString();
    if (response.statusCode == 200) {
      try {
        final decoded = json.decode(body) as Map<String, dynamic>;
        return decoded;
      } catch (e) {
        throw ResumeException('Invalid JSON response: $e');
      }
    } else {
      throw ResumeException('Upload failed (${response.statusCode}): $body');
    }
  }
}

class ResumeException implements Exception {
  final String message;
  ResumeException(this.message);
  @override
  String toString() => 'ResumeException: $message';
}
