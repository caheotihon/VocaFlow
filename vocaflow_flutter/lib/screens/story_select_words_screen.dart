import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/favorite_provider.dart';
import '../providers/story_provider.dart';
import '../models/word_model.dart';
import '../services/api_service.dart';
import '../core/constants/app_constants.dart';

class StorySelectWordsScreen extends StatefulWidget {
  const StorySelectWordsScreen({super.key});

  @override
  State<StorySelectWordsScreen> createState() => _StorySelectWordsScreenState();
}

class _StorySelectWordsScreenState extends State<StorySelectWordsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final ApiService _api = ApiService();

  List<WordModel> _learningWords = [];
  bool _loadingLearning = false;
  final Set<String> _selectedWordIds = {};
  final List<WordModel> _selectedWords = [];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    
    // Fetch data on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoriteProvider>().loadFavorites();
      _loadLearningWords();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLearningWords() async {
    setState(() => _loadingLearning = true);
    try {
      final res = await _api.getReviewToday();
      if (res.data['success'] == true) {
        final wordsJson = res.data['data']['words'] as List? ?? [];
        setState(() {
          _learningWords = wordsJson.map((w) => WordModel.fromJson(w)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading learning words: $e');
    } finally {
      setState(() => _loadingLearning = false);
    }
  }

  void _toggleWord(WordModel word) {
    setState(() {
      if (_selectedWordIds.contains(word.id)) {
        _selectedWordIds.remove(word.id);
        _selectedWords.removeWhere((w) => w.id == word.id);
      } else {
        if (_selectedWordIds.length >= 8) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You can select a maximum of 8 words 📚'),
              backgroundColor: AppColors.primary,
            ),
          );
          return;
        }
        _selectedWordIds.add(word.id);
        _selectedWords.add(word);
      }
    });
  }

  Future<void> _generateStory() async {
    if (_selectedWordIds.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least 3 words to generate a story ✍️'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final storyP = context.read<StoryProvider>();

    // Show high-end loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // AI Pulsing Ring Animation using flutter_animate
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 40),
                  ),
                )
                    .animate(onPlay: (controller) => controller.repeat())
                    .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 800.ms, curve: Curves.easeInOut)
                    .then()
                    .scale(begin: const Offset(1.1, 1.1), end: const Offset(0.9, 0.9), duration: 800.ms, curve: Curves.easeInOut),
                const SizedBox(height: 24),
                const Text(
                  'AI Story Generator',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Weaving your vocabulary into a creative story...',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                )
                    .animate(onPlay: (controller) => controller.repeat())
                    .shimmer(duration: 1500.ms, color: AppColors.primary.withOpacity(0.3)),
                const SizedBox(height: 16),
                const SizedBox(
                  width: 40,
                  child: LinearProgressIndicator(
                    color: AppColors.primary,
                    backgroundColor: AppColors.background,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Call API
    final story = await storyP.generateNewStory(_selectedWordIds.toList());
    
    if (mounted) {
      Navigator.pop(context); // Close loading dialog
    }

    if (story != null && mounted) {
      Navigator.pushReplacementNamed(context, '/story/view');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(storyP.error ?? 'Failed to generate story. Please try again!'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final favProvider = context.watch<FavoriteProvider>();
    final favorites = favProvider.favorites;
    final isFavLoading = favProvider.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Select Words',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          tabs: const [
            Tab(icon: Icon(Icons.favorite_rounded), text: 'Favorites'),
            Tab(icon: Icon(Icons.history_edu_rounded), text: 'Learning'),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabCtrl,
            children: [
              // Favorites Tab
              isFavLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _buildWordList(favorites, 'Your favorites list is empty.\nFavorite words during practice to see them here! ❤️'),
              
              // Learning Tab
              _loadingLearning
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _buildWordList(_learningWords, 'No learning history found.\nStart learning vocabulary first to list words here! 📚'),
            ],
          ),
          
          // Sticky bottom actions bar
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Selected Words', style: AppTextStyles.bodySmall),
                        const SizedBox(height: 2),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '${_selectedWordIds.length}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                              TextSpan(
                                text: ' / 3-8 words',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _selectedWordIds.length >= 3 ? _generateStory : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade200,
                      disabledForegroundColor: Colors.grey.shade400,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      elevation: _selectedWordIds.length >= 3 ? 3 : 0,
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Generate Story',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordList(List<WordModel> list, String emptyMessage) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_stories_rounded, color: AppColors.primary, size: 48),
              ),
              const SizedBox(height: 16),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, height: 1.4, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120), // Large bottom spacing for overlay bar
      itemCount: list.length,
      itemBuilder: (context, index) {
        final word = list[index];
        final isSelected = _selectedWordIds.contains(word.id);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.04) : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isSelected ? AppColors.primary.withOpacity(0.3) : Colors.grey.shade100,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            title: Text(
              word.word,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              word.meaningVn,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            trailing: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                  : null,
            ),
            onTap: () => _toggleWord(word),
          ),
        );
      },
    );
  }
}
