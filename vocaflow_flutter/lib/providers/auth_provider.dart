// Auth Provider — manages auth state globally
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthStatus _status = AuthStatus.unknown;
  UserModel? _user;
  String? _errorMessage;
  bool _isLoading = false;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// Try to restore session from secure storage
  Future<void> tryAutoLogin() async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    try {
      final res = await _api.getMe();
      if (res.data['success'] == true) {
        _user = UserModel.fromJson(res.data['data']['user']);
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (_) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> register(String name, String email, String password) async {
    _setLoading(true);
    try {
      final res = await _api.register(name, email, password);
      if (res.data['success'] == true) {
        await _handleAuthSuccess(res.data);
        return true;
      }
      _errorMessage = res.data['message'];
      return false;
    } catch (e) {
      _errorMessage = _parseError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      final res = await _api.login(email, password);
      if (res.data['success'] == true) {
        await _handleAuthSuccess(res.data);
        return true;
      }
      _errorMessage = res.data['message'];
      return false;
    } catch (e) {
      _errorMessage = _parseError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> _handleAuthSuccess(Map<String, dynamic> data) async {
    final token = data['data']['token'];
    await _storage.write(key: 'auth_token', value: token);
    _user = UserModel.fromJson(data['data']['user']);
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  void _setLoading(bool val) {
    _isLoading = val;
    if (val) _errorMessage = null;
    notifyListeners();
  }

  String _parseError(dynamic e) {
    if (e.toString().contains('connection')) return 'Cannot connect to server';
    return 'An error occurred. Please try again.';
  }
}
