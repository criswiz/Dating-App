import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final ApiClient _client;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthService({required ApiClient apiClient}) : _client = apiClient;

  Future<bool> signup(String email, String password, {String? name}) async {
    final data = await _client.postJson('/auth/signup', {
      'email': email,
      'password': password,
      'name': name,
    });
    return data != null;
  }

  Future<bool> login(String email, String password) async {
    final data = await _client.postJson('/auth/login', {
      'email': email,
      'password': password,
    });
    if (data != null && data['access_token'] != null) {
      final token = data['access_token'];
      await _storage.write(key: 'access_token', value: token);
      return true;
    }
    return false;
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'access_token');
  }

  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
  }

  /// Fetch public profiles (uses ApiClient which attaches token automatically)
  Future<List<dynamic>?> fetchProfiles() async {
    final data = await _client.getJson('/profiles/');
    if (data is List) return List<dynamic>.from(data);
    return null;
  }
}
