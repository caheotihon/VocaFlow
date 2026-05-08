// Stats Provider
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class StatsProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  Map<String, dynamic>? _dashboard;
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get dashboard => _dashboard;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadDashboard() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _api.getDashboard();
      if (res.data['success'] == true) {
        _dashboard = res.data['data'];
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
