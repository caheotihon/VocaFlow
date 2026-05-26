// My Wordbook Screen — Integrates Favorites & Learned Words
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/favorite_provider.dart';
import '../providers/learn_provider.dart';
import '../models/word_model.dart';
import '../core/constants/app_constants.dart';
import 'widgets/shared_widgets.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});
  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _search = '';
  String _selectedStatusFilter = 'all'; // 'all', 'mastered', 'reviewing', 'learning', 'new'
  String _sortBy = 'word_asc'; // 'word_asc', 'word_desc', 'mastery_desc', 'mastery_asc'


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        // Clear search when switching tabs to avoid confusion
        _search = '';
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final favP = context.read<FavoriteProvider>();
      favP.loadFavorites();
      favP.loadLearnedWords();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final favP = context.watch<FavoriteProvider>();

    // ── Filtering Logic for Search ─────────────────────────────────────
    final filteredFavs = favP.favorites.where((w) =>
        w.word.toLowerCase().contains(_search.toLowerCase()) ||
        w.meaningVn.toLowerCase().contains(_search.toLowerCase())).toList();

    final filteredLearned = favP.learnedWords.where((item) {
      final WordModel w = item['word'];
      return w.word.toLowerCase().contains(_search.toLowerCase()) ||
          w.meaningVn.toLowerCase().contains(_search.toLowerCase());
    }).toList();

    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: LingoAppBar(
        title: 'My Wordbook',
        showStreak: false,
        showBackButton: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text('Favorites (${favP.favorites.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.school_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text('Learned (${favP.learnedWords.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isWide ? 1024 : 800),
            child: Column(
              children: [
                const SizedBox(height: 16),

                // ── Unified Search Bar ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v),
                    decoration: InputDecoration(
                      hintText: _tabController.index == 0
                          ? 'Search favorites...'
                          : 'Search learned vocabulary...',
                      prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Tab Contents ───────────────────────────────────────────────
                Expanded(
                  child: favP.isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            // ── TAB 1: FAVORITES ─────────────────────────────────────
                            _buildFavoritesTab(filteredFavs, favP, isWide, width),

                            // ── TAB 2: LEARNED WORDS ──────────────────────────────────
                            _buildLearnedTab(filteredLearned, favP, isWide, width),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _buildDynamicFAB(filteredFavs, filteredLearned),
    );
  }

  // ── Widgets: Favorites Tab ──────────────────────────────────────────────────
  Widget _buildFavoritesTab(List<WordModel> words, FavoriteProvider favP, bool isWide, double width) {
    if (words.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border_rounded, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('No favorites yet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            const Text('Tap ♡ on any word while practicing', style: AppTextStyles.bodySmall),
          ],
        ),
      );
    }

    return isWide
        ? GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: width >= 900 ? 3 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              mainAxisExtent: 120,
            ),
            itemCount: words.length,
            itemBuilder: (_, i) {
              final word = words[i];
              return _buildFavoriteCard(word, favP);
            },
          )
        : ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            itemCount: words.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final word = words[i];
              return Dismissible(
                key: Key('fav_${word.id}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: const Icon(Icons.delete_outline, color: AppColors.error, size: 26),
                ),
                onDismissed: (_) => favP.toggleFavorite(word),
                child: _buildFavoriteListRow(word, favP),
              );
            },
          );
  }

  // ── Widgets: Learned Words Tab ─────────────────────────────────────────────
  Widget _buildFilterChip(String label, String statusKey, int count, Color color) {
    final isSelected = _selectedStatusFilter == statusKey;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text('$label ($count)'),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        selectedColor: color,
        backgroundColor: color.withOpacity(0.08),
        checkmarkColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
          side: BorderSide(color: color.withOpacity(0.2), width: 1),
        ),
        onSelected: (bool selected) {
          setState(() {
            _selectedStatusFilter = statusKey;
          });
        },
      ),
    );
  }

  Widget _buildFilterRow(int total, int mastered, int reviewing, int learning, int newCount) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          _buildFilterChip('All', 'all', total, AppColors.primary),
          _buildFilterChip('Mastered', 'mastered', mastered, AppColors.mastered),
          _buildFilterChip('Reviewing', 'reviewing', reviewing, AppColors.reviewing),
          _buildFilterChip('Learning', 'learning', learning, AppColors.learning),
          _buildFilterChip('New', 'new', newCount, AppColors.newWord),
        ],
      ),
    );
  }

  Widget _buildHeaderRow(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$count words displayed',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            children: [
              const Icon(Icons.sort_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                initialValue: _sortBy,
                onSelected: (val) {
                  setState(() {
                    _sortBy = val;
                  });
                },
                child: Text(
                  _getSortLabel(_sortBy),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'word_asc', child: Text('Alphabet (A-Z)')),
                  const PopupMenuItem(value: 'word_desc', child: Text('Alphabet (Z-A)')),
                  const PopupMenuItem(value: 'mastery_desc', child: Text('Mastery (High to Low)')),
                  const PopupMenuItem(value: 'mastery_asc', child: Text('Mastery (Low to High)')),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getSortLabel(String sortBy) {
    switch (sortBy) {
      case 'word_desc':
        return 'Alphabet (Z-A)';
      case 'mastery_desc':
        return 'Mastery (Highest)';
      case 'mastery_asc':
        return 'Mastery (Lowest)';
      default:
        return 'Alphabet (A-Z)';
    }
  }

  Widget _buildLearnedTab(List<Map<String, dynamic>> items, FavoriteProvider favP, bool isWide, double width) {
    final learnedWords = favP.learnedWords;
    if (learnedWords.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('No learned words yet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            const Text('Complete practice decks to master vocabulary!', style: AppTextStyles.bodySmall),
          ],
        ),
      );
    }

    final total = learnedWords.length;
    final masteredCount = learnedWords.where((item) => item['status'] == 'mastered').length;
    final reviewingCount = learnedWords.where((item) => item['status'] == 'reviewing').length;
    final learningCount = learnedWords.where((item) => item['status'] == 'learning').length;
    final newCount = learnedWords.where((item) => item['status'] == 'new' || item['status'] == 'newWord').length;

    // 1. Filter by status
    List<Map<String, dynamic>> displayed = items;
    if (_selectedStatusFilter != 'all') {
      displayed = items.where((item) {
        final status = item['status'] ?? 'learning';
        if (_selectedStatusFilter == 'new') {
          return status == 'new' || status == 'newWord';
        }
        return status == _selectedStatusFilter;
      }).toList();
    }

    // 2. Sort
    List<Map<String, dynamic>> sorted = List.from(displayed);
    if (_sortBy == 'word_asc') {
      sorted.sort((a, b) => (a['word'] as WordModel).word.toLowerCase().compareTo((b['word'] as WordModel).word.toLowerCase()));
    } else if (_sortBy == 'word_desc') {
      sorted.sort((a, b) => (b['word'] as WordModel).word.toLowerCase().compareTo((a['word'] as WordModel).word.toLowerCase()));
    } else if (_sortBy == 'mastery_desc') {
      sorted.sort((a, b) => (b['mastery'] as int? ?? 0).compareTo(a['mastery'] as int? ?? 0));
    } else if (_sortBy == 'mastery_asc') {
      sorted.sort((a, b) => (a['mastery'] as int? ?? 0).compareTo(b['mastery'] as int? ?? 0));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterRow(total, masteredCount, reviewingCount, learningCount, newCount),
        _buildHeaderRow(sorted.length),
        Expanded(
          child: sorted.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      const Text(
                        'No words match this filter / search',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : isWide
                  ? GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: width >= 900 ? 3 : 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        mainAxisExtent: 130,
                      ),
                      itemCount: sorted.length,
                      itemBuilder: (_, i) {
                        final item = sorted[i];
                        return _buildLearnedCard(item, favP);
                      },
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      itemCount: sorted.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final item = sorted[i];
                        return _buildLearnedListRow(item, favP);
                      },
                    ),
        ),
      ],
    );
  }

  // ── Card & Row Builders: Favorites ──────────────────────────────────────────
  Widget _buildFavoriteCard(WordModel word, FavoriteProvider favP) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(word.level,
                          style: const TextStyle(
                              color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 11)),
                    ),
                    if (word.partOfSpeech.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(word.partOfSpeech,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(word.word,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(word.meaningVn,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.favorite, color: Colors.pinkAccent),
            onPressed: () => favP.toggleFavorite(word),
            mouseCursor: SystemMouseCursors.click,
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteListRow(WordModel word, FavoriteProvider favP) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(word.level,
                style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(word.word, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(word.meaningVn, style: AppTextStyles.bodySmall),
                if (word.partOfSpeech.isNotEmpty)
                  Text(word.partOfSpeech,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.favorite, color: Colors.pinkAccent),
            onPressed: () => favP.toggleFavorite(word),
            mouseCursor: SystemMouseCursors.click,
          ),
        ],
      ),
    );
  }

  // ── Card & Row Builders: Learned Words ──────────────────────────────────────
  Widget _buildLearnedCard(Map<String, dynamic> item, FavoriteProvider favP) {
    final WordModel word = item['word'];
    final String status = item['status'] ?? 'learning';
    final int mastery = item['mastery'] ?? 0;
    final bool isFav = favP.isFavorite(word.id);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(word.level,
                          style: const TextStyle(
                              color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 11)),
                    ),
                    const SizedBox(width: 8),
                    _buildMasteryChip(status, mastery),
                  ],
                ),
                const SizedBox(height: 8),
                Text(word.word,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(word.meaningVn,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          IconButton(
            icon: Icon(isFav ? Icons.favorite : Icons.favorite_border_rounded,
                color: isFav ? Colors.pinkAccent : Colors.grey.shade400),
            onPressed: () => favP.toggleFavorite(word),
            mouseCursor: SystemMouseCursors.click,
          ),
        ],
      ),
    );
  }

  Widget _buildLearnedListRow(Map<String, dynamic> item, FavoriteProvider favP) {
    final WordModel word = item['word'];
    final String status = item['status'] ?? 'learning';
    final int mastery = item['mastery'] ?? 0;
    final bool isFav = favP.isFavorite(word.id);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(word.level,
                    style: const TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
              const SizedBox(height: 8),
              _buildMasteryChip(status, mastery),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(word.word, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(word.meaningVn, style: AppTextStyles.bodySmall),
                if (word.partOfSpeech.isNotEmpty)
                  Text(word.partOfSpeech,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(isFav ? Icons.favorite : Icons.favorite_border_rounded,
                color: isFav ? Colors.pinkAccent : Colors.grey.shade400),
            onPressed: () => favP.toggleFavorite(word),
            mouseCursor: SystemMouseCursors.click,
          ),
        ],
      ),
    );
  }

  Widget _buildMasteryChip(String status, int mastery) {
    Color color;
    String label;
    switch (status) {
      case 'mastered':
        color = AppColors.success;
        label = 'Mastered';
        break;
      case 'reviewing':
        color = AppColors.info;
        label = 'Review';
        break;
      case 'learning':
        color = AppColors.learning;
        label = 'Learn';
        break;
      default:
        color = AppColors.newWord;
        label = 'New';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withOpacity(0.2), width: 0.5),
      ),
      child: Text(
        '$label ($mastery%)',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }

  // ── Dynamic Floating Action Button ──────────────────────────────────────────
  Widget? _buildDynamicFAB(List<WordModel> favs, List<Map<String, dynamic>> learned) {
    if (_tabController.index == 0) {
      // TAB 1: Practice Favorites
      return favs.isNotEmpty
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              onPressed: () {
                final lp = context.read<LearnProvider>();
                lp.selectedSource = 'Favorites';
                lp.selectedLevel = null;
                lp.selectedTopic = null;
                lp.selectMode('flashcard');
                Navigator.pushNamed(context, '/choose-mode');
              },
              icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
              label: const Text('Practice Favorites',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            )
          : null;
    } else {
      // TAB 2: Review Learned Words
      return learned.isNotEmpty
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.secondary,
              onPressed: () {
                final lp = context.read<LearnProvider>();
                lp.selectedSource = 'Review';
                lp.selectedLevel = null;
                lp.selectedTopic = null;
                lp.selectMode('flashcard');
                Navigator.pushNamed(context, '/choose-mode');
              },
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              label: const Text('Review Mastered',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            )
          : null;
    }
  }
}