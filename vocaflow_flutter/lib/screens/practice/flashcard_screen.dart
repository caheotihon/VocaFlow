// Flashcard Mode — flip animation between word and meaning
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/learn_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../core/constants/app_constants.dart';
import '../widgets/shared_widgets.dart';

class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({super.key});
  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipCtrl;
  late Animation<double> _flipAnim;
  bool _showBack = false;
  bool _answering = false;
  final _startTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _flipAnim = Tween<double>(begin: 0, end: math.pi)
        .animate(CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  void _flip() {
    if (_flipCtrl.isAnimating) return;
    if (_showBack) {
      _flipCtrl.reverse();
    } else {
      _flipCtrl.forward();
    }
    setState(() => _showBack = !_showBack);
  }

  Future<void> _answer(bool correct) async {
    if (_answering) return;
    setState(() => _answering = true);
    final ms = DateTime.now().difference(_startTime).inMilliseconds;
    await context.read<LearnProvider>().submitAnswer(correct, timeTakenMs: ms);

    final lp = context.read<LearnProvider>();
    if (lp.isSessionComplete) {
      final result = await lp.completeSession();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/result', arguments: result);
      }
    } else {
      // Reset flip for next card
      _flipCtrl.reset();
      setState(() { _showBack = false; _answering = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lp   = context.watch<LearnProvider>();
    final favP = context.watch<FavoriteProvider>();
    final word = lp.currentWord;
    if (word == null) return const SizedBox.shrink();

    final total   = lp.session?.words.length ?? 1;
    final current = lp.session?.currentIndex ?? 0;
    final progress = current / total;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: BackButton(
          color: AppColors.textPrimary,
          onPressed: () => _showExitDialog(context),
        ),
        centerTitle: true,
        title: Text('$current / $total',
            style: const TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: Icon(
              favP.isFavorite(word.id)
                  ? Icons.favorite : Icons.favorite_border,
              color: favP.isFavorite(word.id) ? Colors.pinkAccent : AppColors.textSecondary,
            ),
            onPressed: () => favP.toggleFavorite(word),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            // Progress
            AppProgressBar(value: progress, height: 6),
            const SizedBox(height: 24),

            // Flip card
            Expanded(
              child: GestureDetector(
                onTap: _flip,
                child: AnimatedBuilder(
                  animation: _flipAnim,
                  builder: (_, child) {
                    final angle = _flipAnim.value;
                    final isFront = angle < math.pi / 2;
                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(angle),
                      child: isFront
                          ? _CardFace(
                              word: word.word,
                              partOfSpeech: word.partOfSpeech,
                              pronunciation: word.pronunciation,
                              tags: word.tags,
                            )
                          : Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()..rotateY(math.pi),
                              child: _CardBack(
                                meaningVn:    word.meaningVn,
                                definitionVn: word.definitionVn,
                                definitionEn: word.definitionEn,
                                example:      word.example,
                              ),
                            ),
                    );
                  },
                ),
              ),
            ),

            // Hint text
            if (!_showBack) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.touch_app, color: AppColors.textHint, size: 16),
                  const SizedBox(width: 6),
                  Text('Tap card to reveal meaning',
                      style: AppTextStyles.bodySmall),
                ],
              ),
            ],

            // Answer buttons
            if (_showBack) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _answering ? null : () => _answer(false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: AppColors.error.withOpacity(0.3)),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.close_rounded, color: AppColors.error, size: 28),
                            SizedBox(height: 4),
                            Text('Didn\'t know',
                                style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _answering ? null : () => _answer(true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: AppColors.success.withOpacity(0.3)),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.check_rounded, color: AppColors.success, size: 28),
                            SizedBox(height: 4),
                            Text('Got it!',
                                style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: const Text('Exit Session?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Your progress in this session will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<LearnProvider>().resetSession();
              Navigator.popUntil(context, ModalRoute.withName('/home'));
            },
            child: const Text('Exit', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  final String word, partOfSpeech, pronunciation;
  final List<String> tags;
  const _CardFace({
    required this.word, required this.partOfSpeech,
    required this.pronunciation, required this.tags,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withOpacity(0.3),
              blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(partOfSpeech,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ),
          const SizedBox(height: 24),
          Text(word,
              style: const TextStyle(
                fontSize: 44, fontWeight: FontWeight.w800,
                color: Colors.white, letterSpacing: -1,
              )),
          if (pronunciation.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('/$pronunciation/',
                style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 16)),
          ],
          const SizedBox(height: 24),
          if (tags.isNotEmpty)
            Wrap(
              spacing: 8,
              children: tags.map((t) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(t, style: const TextStyle(color: Colors.white70, fontSize: 11)),
              )).toList(),
            ),
        ],
      ),
    );
  }
}

class _CardBack extends StatelessWidget {
  final String meaningVn, definitionVn, definitionEn, example;
  const _CardBack({
    required this.meaningVn, required this.definitionVn,
    required this.definitionEn, required this.example,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08),
              blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(meaningVn,
              style: const TextStyle(
                fontSize: 28, fontWeight: FontWeight.w800,
                color: AppColors.primary)),
          const SizedBox(height: 16),
          if (definitionVn.isNotEmpty) ...[
            const Text('Định nghĩa:', style: AppTextStyles.label),
            const SizedBox(height: 4),
            Text(definitionVn, style: AppTextStyles.body),
            const SizedBox(height: 14),
          ],
          if (example.isNotEmpty) ...[
            const Text('Ví dụ:', style: AppTextStyles.label),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Text(example,
                  style: AppTextStyles.body.copyWith(
                    fontStyle: FontStyle.italic, color: AppColors.textSecondary)),
            ),
          ],
        ],
      ),
    );
  }
}
