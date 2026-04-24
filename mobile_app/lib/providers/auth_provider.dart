import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthService? _service;
  String? _token;
  int? _currentUserId;
  String? _currentUserPhotoUrl;

  AuthProvider({AuthService? service}) : _service = service;

  String? get token => _token;
  bool get isAuthenticated => _token != null;
  int? get currentUserId => _currentUserId;
  String? get currentUserPhotoUrl => _currentUserPhotoUrl;

  Future<bool> signup(String email, String password, {String? name}) async {
    if (_service == null) throw Exception('AuthService not set');
    final ok = await _service!.signup(email, password, name: name);
    if (ok) {
      return login(email, password);
    }
    return false;
  }

  Future<bool> login(String email, String password) async {
    if (_service == null) throw Exception('AuthService not set');
    final ok = await _service!.login(email, password);
    if (ok) {
      _token = await _service!.getToken();
      await _loadUserProfile();
      notifyListeners();
    }
    return ok;
  }

  Future<void> logout() async {
    if (_service == null) throw Exception('AuthService not set');
    await _service!.logout();
    _token = null;
    _currentUserId = null;
    _currentUserPhotoUrl = null;
    notifyListeners();
  }

  Future<void> loadFromStorage() async {
    if (_service == null) return;
    _token = await _service!.getToken();
    if (_token != null) {
      await _loadUserProfile();
    }
    notifyListeners();
  }

  Future<void> _loadUserProfile() async {
    final profile = await _service!.fetchMyProfile();
    if (profile != null) {
      _currentUserId = profile['id'] as int?;
      _currentUserPhotoUrl = profile['photo_url'] as String?;
    }
  }

  void setService(AuthService service) {
    _service = service;
    loadFromStorage();
  }
}
