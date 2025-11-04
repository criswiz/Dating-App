import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthService? _service;
  String? _token;

  AuthProvider({AuthService? service}) : _service = service;

  String? get token => _token;
  bool get isAuthenticated => _token != null;

  Future<bool> signup(String email, String password, {String? name}) async {
    if (_service == null) throw Exception('AuthService not set');
    final ok = await _service!.signup(email, password, name: name);
    if (ok) {
      final logged = await login(email, password);
      return logged;
    }
    return false;
  }

  Future<bool> login(String email, String password) async {
    if (_service == null) throw Exception('AuthService not set');
    final ok = await _service!.login(email, password);
    if (ok) {
      _token = await _service!.getToken();
      notifyListeners();
    }
    return ok;
  }

  Future<void> logout() async {
    if (_service == null) throw Exception('AuthService not set');
    await _service!.logout();
    _token = null;
    notifyListeners();
  }

  Future<void> loadFromStorage() async {
    if (_service == null) return;
    _token = await _service!.getToken();
    notifyListeners();
  }

  // allow injecting a constructed AuthService after providers are wired
  void setService(AuthService service) {
    _service = service;
    loadFromStorage();
  }
}
