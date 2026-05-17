// Stats Provider
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class StatsProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  Map<String, dynamic>? _dashboard;
  List<dynamic> _leaderboard = [];
  Map<String, dynamic>? _myRank;
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get dashboard => _dashboard;
  List<dynamic> get leaderboard => _leaderboard;
  Map<String, dynamic>? get myRank => _myRank;
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

  Future<void> loadLeaderboard({String sortBy = 'xp'}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.getLeaderboard(type: sortBy);
      if (res.data['success'] == true) {
        _leaderboard = res.data['data']['leaderboard'];
        _myRank = res.data['data']['myRank'];
      }
    } catch (e) {
      _error = e.toString();
      _leaderboard = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
