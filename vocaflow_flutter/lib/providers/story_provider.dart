import 'package:flutter/material.dart';
import '../models/story_model.dart';
import '../services/api_service.dart';

class StoryProvider extends ChangeNotifier {
  final ApiService _api;

  /// Default constructor — creates its own [ApiService] instance.
  StoryProvider() : _api = ApiService();

  /// Test constructor — accepts an injected [ApiService] for unit testing.
  StoryProvider.withApi(ApiService api) : _api = api;

  List<StoryModel> _stories = [];
  StoryModel? _currentStory;
  bool _isLoading = false;
  String? _error;

  List<StoryModel> get stories => _stories;
  StoryModel? get currentStory => _currentStory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void setCurrentStory(StoryModel? story) {
    _currentStory = story;
    notifyListeners();
  }

  Future<StoryModel?> generateNewStory(List<String> wordIds) async {
    _setLoading(true);
    _error = null;
    try {
      final res = await _api.generateStory(wordIds);
      if (res.data['success'] == true) {
        final newStory = StoryModel.fromJson(res.data['data']);
        _currentStory = newStory;
        // Insert at the beginning of history list
        _stories.insert(0, newStory);
        return newStory;
      } else {
        _error = res.data['message'] ?? 'Failed to generate story';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
    return null;
  }

  Future<void> fetchUserStories() async {
    _setLoading(true);
    _error = null;
    try {
      final res = await _api.getStories();
      if (res.data['success'] == true) {
        _stories = (res.data['data'] as List)
            .map((s) => StoryModel.fromJson(s))
            .toList();
      } else {
        _error = res.data['message'] ?? 'Failed to fetch stories';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteStory(String storyId) async {
    _error = null;
    try {
      final res = await _api.deleteStory(storyId);
      if (res.data['success'] == true) {
        _stories.removeWhere((s) => s.id == storyId);
        notifyListeners();
        return true;
      } else {
        _error = res.data['message'] ?? 'Failed to delete story';
      }
    } catch (e) {
      _error = e.toString();
    }
    return false;
  }

  Future<bool> finishStoryQuiz(String storyId) async {
    try {
      final res = await _api.completeStoryQuiz(storyId);
      if (res.data['success'] == true) {
        // Update story completion status in local lists
        final updatedData = res.data['data']['story'];
        final updatedStory = StoryModel.fromJson(updatedData);

        if (_currentStory?.id == storyId) {
          _currentStory = updatedStory;
        }

        final idx = _stories.indexWhere((s) => s.id == storyId);
        if (idx != -1) {
          _stories[idx] = updatedStory;
        }

        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = e.toString();
    }
    return false;
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}
