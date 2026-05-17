// Favorites Screen
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/favorite_provider.dart';
import '../providers/learn_provider.dart';
import '../core/constants/app_constants.dart';
import 'widgets/shared_widgets.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});
  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  String _search = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoriteProvider>().loadFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    final favP = context.watch<FavoriteProvider>();
    final words = favP.favorites.where((w) =>
        w.word.toLowerCase().contains(_search.toLowerCase()) ||
        w.meaningVn.toLowerCase().contains(_search.toLowerCase())).toList();

    final canPop = Navigator.canPop(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        // ── Responsive Layout ────────────────────────────────────────────────
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                // ── Header with optional Back button ──────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 16, 20, 0),
                  child: Row(
                    children: [
                      if (canPop)
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: AppColors.textPrimary, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(left: canPop ? 0 : 8),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Favorites', style: AppTextStyles.h2),
                              Text('Your saved vocabulary', style: AppTextStyles.bodySmall),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          '${words.length} words',
                          style: const TextStyle(
                              color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Search ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v),
                    decoration: InputDecoration(
                      hintText: 'Search favorites...',
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

                // ── List ───────────────────────────────────────────────
                Expanded(
                  child: favP.isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : words.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.favorite_border_rounded,
                                      size: 64, color: Colors.grey.shade300),
                                  const SizedBox(height: 16),
                                  const Text('No favorites yet',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                                          color: AppColors.textSecondary)),
                                  const SizedBox(height: 6),
                                  const Text('Tap ♡ on any word while practicing',
                                      style: AppTextStyles.bodySmall),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              itemCount: words.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (_, i) {
                                final word = words[i];
                                return Dismissible(
                                  key: Key(word.id),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    decoration: BoxDecoration(
                                      color: AppColors.error.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(AppRadius.lg),
                                    ),
                                    child: const Icon(Icons.delete_outline,
                                        color: AppColors.error, size: 26),
                                  ),
                                  onDismissed: (_) => favP.toggleFavorite(word),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(AppRadius.lg),
                                      border: Border.all(color: Colors.grey.shade100),
                                      boxShadow: [
                                        BoxShadow(color: Colors.black.withOpacity(0.04),
                                            blurRadius: 8, offset: const Offset(0, 2)),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        // Level badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(AppRadius.full),
                                          ),
                                          child: Text(word.level,
                                              style: const TextStyle(
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.w700, fontSize: 12)),
                                        ),
                                        const SizedBox(width: 14),
                                        // Word info
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(word.word,
                                                  style: const TextStyle(
                                                      fontSize: 17, fontWeight: FontWeight.w700)),
                                              const SizedBox(height: 2),
                                              Text(word.meaningVn,
                                                  style: AppTextStyles.bodySmall),
                                              if (word.partOfSpeech.isNotEmpty)
                                                Text(word.partOfSpeech,
                                                    style: const TextStyle(
                                                        fontSize: 11,
                                                        color: AppColors.textSecondary,
                                                        fontStyle: FontStyle.italic)),
                                            ],
                                          ),
                                        ),
                                        // Favorite button
                                        IconButton(
                                          icon: const Icon(Icons.favorite,
                                              color: Colors.pinkAccent),
                                          onPressed: () => favP.toggleFavorite(word),
                                          mouseCursor: SystemMouseCursors.click, // Tối ưu cho Web
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: words.isNotEmpty
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              onPressed: () {
                context.read<LearnProvider>().selectMode('flashcard');
                Navigator.pushNamed(context, '/choose-mode');
              },
              icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
              label: const Text('Practice',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            )
          : null,
    );
  }
}