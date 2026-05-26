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
  bool get isAdmin => _user?.role == 'admin';

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

  /// Reload user profile details from the server to sync streak, XP, and badges
  Future<void> refreshUser() async {
    try {
      final res = await _api.getMe();
      if (res.data['success'] == true) {
        _user = UserModel.fromJson(res.data['data']['user']);
        notifyListeners();
      }
    } catch (_) {}
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

  /// Google Sign-In — pass profile data from google_sign_in package
  Future<bool> loginWithGoogle({
    String? idToken,
    String? email,
    String? name,
    String? avatar,
    String? googleId,
  }) async {
    _setLoading(true);
    try {
      final res = await _api.googleLogin(
        idToken: idToken,
        email: email,
        name: name,
        avatar: avatar,
        googleId: googleId,
      );
      if (res.data['success'] == true) {
        await _handleAuthSuccess(res.data);
        return true;
      }
      _errorMessage = res.data['message'] ?? 'Google sign-in failed';
      return false;
    } catch (e) {
      _errorMessage = _parseError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update profile (name, bio, dailyGoal, goalAccuracy, avatar URL)
  Future<bool> updateProfile({
    String? name,
    String? bio,
    String? avatar,
    int? dailyGoal,
    int? goalAccuracy,
  }) async {
    _setLoading(true);
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (bio != null) data['bio'] = bio;
      if (avatar != null) data['avatar'] = avatar;
      if (dailyGoal != null) data['dailyGoal'] = dailyGoal;
      if (goalAccuracy != null) data['goalAccuracy'] = goalAccuracy;

      final res = await _api.updateProfile(data);
      if (res.data['success'] == true) {
        _user = UserModel.fromJson(res.data['data']['user']);
        notifyListeners();
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
    final msg = e.toString();
    if (msg.contains('connection') || msg.contains('SocketException')) {
      return 'Cannot connect to server. Check your connection.';
    }
    if (msg.contains('401')) return 'Invalid credentials';
    if (msg.contains('409')) return 'Email already registered';
    return 'An error occurred. Please try again.';
  }
}
