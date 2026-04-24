import 'dart:io';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _client;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthService({required ApiClient apiClient}) : _client = apiClient;

  // ── Auth ────────────────────────────────────────────────────────────────────

  Future<bool> signup(String email, String password, {String? name}) async {
    final data = await _client.postJson('/auth/signup', {
      'email': email,
      'password': password,
      if (name != null) 'name': name,
    });
    return data != null;
  }

  Future<bool> login(String email, String password) async {
    final data = await _client.postJson('/auth/login', {
      'email': email,
      'password': password,
    });
    if (data != null && data['access_token'] != null) {
      await _storage.write(key: 'access_token', value: data['access_token']);
      if (data['refresh_token'] != null) {
        await _storage.write(key: 'refresh_token', value: data['refresh_token']);
      }
      return true;
    }
    return false;
  }

  Future<bool> refreshToken() async {
    final refreshToken = await _storage.read(key: 'refresh_token');
    if (refreshToken == null) return false;
    final resp = await _client.post('/auth/refresh', {'refresh_token': refreshToken});
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final data = jsonDecode(resp.body);
      await _storage.write(key: 'access_token', value: data['access_token']);
      if (data['refresh_token'] != null) {
        await _storage.write(key: 'refresh_token', value: data['refresh_token']);
      }
      return true;
    }
    return false;
  }

  Future<String?> getToken() async => _storage.read(key: 'access_token');

  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }

  // ── Profile ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> fetchMyProfile() async {
    final data = await _client.getJson('/auth/me');
    if (data is Map<String, dynamic>) return data;
    return null;
  }

  Future<Map<String, dynamic>?> updateProfile(Map<String, dynamic> fields) async {
    final data = await _client.patchJson('/profiles/me', fields);
    if (data is Map<String, dynamic>) return data;
    return null;
  }

  Future<Map<String, dynamic>?> uploadPhoto(File file) async {
    final resp = await _client.uploadFile('/profiles/me/photo', file, 'file');
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final data = jsonDecode(resp.body);
      if (data is Map<String, dynamic>) return data;
    }
    return null;
  }

  // ── Discovery ────────────────────────────────────────────────────────────────

  Future<List<dynamic>?> fetchProfiles({
    int? minAge,
    int? maxAge,
    String? intent,
    String? tribe,
    String? religion,
    String? relationshipStatus,
    String? hasKids,
    String? search,
  }) async {
    final params = <String, String>{};
    if (minAge != null) params['min_age'] = '$minAge';
    if (maxAge != null) params['max_age'] = '$maxAge';
    if (intent != null && intent.isNotEmpty) params['intent'] = intent;
    if (tribe != null && tribe.isNotEmpty) params['tribe'] = tribe;
    if (religion != null && religion.isNotEmpty) params['religion'] = religion;
    if (relationshipStatus != null && relationshipStatus.isNotEmpty) {
      params['relationship_status'] = relationshipStatus;
    }
    if (hasKids != null && hasKids.isNotEmpty) params['has_kids'] = hasKids;
    if (search != null && search.isNotEmpty) params['search'] = search;

    final query = params.isEmpty
        ? ''
        : '?${params.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&')}';
    final data = await _client.getJson('/profiles/discover$query');
    if (data is List) return List<dynamic>.from(data);
    return null;
  }

  // ── Matching ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> likeProfile(int targetUserId) async {
    final data = await _client.postJson('/matches/like', {'target_user_id': targetUserId});
    if (data is Map<String, dynamic>) return data;
    return null;
  }

  Future<Map<String, dynamic>?> passProfile(int targetUserId) async {
    final data = await _client.postJson('/matches/pass', {'target_user_id': targetUserId});
    if (data is Map<String, dynamic>) return data;
    return null;
  }

  Future<List<dynamic>?> fetchMatches() async {
    final data = await _client.getJson('/matches/');
    if (data is List) return List<dynamic>.from(data);
    return null;
  }

  // ── Chat ──────────────────────────────────────────────────────────────────────

  Future<List<dynamic>?> fetchThreads() async {
    final data = await _client.getJson('/chat/threads');
    if (data is List) return List<dynamic>.from(data);
    return null;
  }

  Future<List<dynamic>?> fetchMessages(int threadId) async {
    final data = await _client.getJson('/chat/threads/$threadId/messages');
    if (data is List) return List<dynamic>.from(data);
    return null;
  }

  Future<Map<String, dynamic>?> sendMessage(int threadId, String content) async {
    final data = await _client.postJson('/chat/threads/$threadId/messages', {'content': content});
    if (data is Map<String, dynamic>) return data;
    return null;
  }

  // ── Safety ────────────────────────────────────────────────────────────────────

  Future<bool> blockUser(int userId, {String? reason}) async {
    final body = <String, dynamic>{'blocked_user_id': userId};
    if (reason != null) body['reason'] = reason;
    final data = await _client.postJson('/safety/block', body);
    return data != null;
  }

  Future<bool> reportUser(int userId, String reason) async {
    final data = await _client.postJson('/safety/report', {
      'reported_user_id': userId,
      'reason': reason,
    });
    return data != null;
  }
}
