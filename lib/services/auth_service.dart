import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  // Base URL handling for different platforms.
  String get _baseUrl {
    // Android emulator needs 10.0.2.2 to reach host machine.
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://localhost:8000';
  }

  Future<TokenResponse> signin(String email, String password) async {
    final uri = Uri.parse('$_baseUrl/api/auth/signin');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': email, 'password': password},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final token = TokenResponse.fromJson(data);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token.accessToken);
      return token;
    } else if (response.statusCode == 401) {
      throw AuthException('Invalid credentials');
    } else {
      throw AuthException('Signin failed (${response.statusCode})');
    }
  }

  Future<UserPublic> signup(
    String email,
    String password,
    String? fullName,
  ) async {
    final uri = Uri.parse('$_baseUrl/api/auth/signup');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
        'full_name': fullName,
      }),
    );
    if (response.statusCode == 201) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return UserPublic.fromJson(data);
    } else if (response.statusCode == 400) {
      throw AuthException('Email already registered');
    } else {
      throw AuthException('Signup failed (${response.statusCode})');
    }
  }

  Future<UserPublic?> me() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return null;
    final uri = Uri.parse('$_baseUrl/api/auth/me');
    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return UserPublic.fromJson(data);
    } else if (response.statusCode == 401) {
      // Token invalid/expired
      await prefs.remove('auth_token');
      return null;
    } else {
      throw AuthException('Fetch profile failed (${response.statusCode})');
    }
  }

  Future<void> signout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Future<bool> isSignedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('auth_token');
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => 'AuthException: $message';
}
