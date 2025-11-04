import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  final String baseUrl;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Future<String?> Function()? tokenGetter;

  ApiClient({this.baseUrl = 'http://127.0.0.1:8000', this.tokenGetter});

  Future<Map<String, String>> _defaultHeaders() async {
    String? token;
    if (tokenGetter != null) {
      token = await tokenGetter!();
    }
    token ??= await _storage.read(key: 'access_token');
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  Future<http.Response> get(String path) async {
    final headers = await _defaultHeaders();
    return http.get(Uri.parse('$baseUrl$path'), headers: headers);
  }

  Future<http.Response> post(String path, Map body) async {
    final headers = await _defaultHeaders();
    return http.post(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  Future<dynamic> getJson(String path) async {
    final resp = await get(path);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return jsonDecode(resp.body);
    }
    return null;
  }

  Future<dynamic> postJson(String path, Map body) async {
    final resp = await post(path, body);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return jsonDecode(resp.body);
    }
    return null;
  }
}
