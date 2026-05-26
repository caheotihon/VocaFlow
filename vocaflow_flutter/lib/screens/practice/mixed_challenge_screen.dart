// Mixed Challenge Screen — randomly picks a mode per word
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/learn_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../core/constants/app_constants.dart';
import '../widgets/shared_widgets.dart';

// Import individual screens for embedding
import 'flashcard_screen.dart';
import 'multiple_choice_practice_screen.dart';

enum _MixedMode { flashcard, fillBlank, reverse }

class MixedChallengeScreen extends StatefulWidget {
  const MixedChallengeScreen({super.key});
  @override
  State<MixedChallengeScreen> createState() => _MixedChallengeScreenState();
}

class _MixedChallengeScreenState extends State<MixedChallengeScreen> {
  _MixedMode _mode = _MixedMode.flashcard;
  final _rand = math.Random();
  DateTime _wordStartTime = DateTime.now();
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _nextMode();
  }

  void _nextMode() {
    final modes = _MixedMode.values;
    _mode = modes[_rand.nextInt(modes.length)];
    setState(() {
      _submitted = false;
      _wordStartTime = DateTime.now();
    });
  }

  Future<void> _answer(bool correct) async {
    if (_submitted) return;
    setState(() => _submitted = true);
    final lp = context.read<LearnProvider>();
    final word = lp.currentWord;
    final ms = DateTime.now().difference(_wordStartTime).inMilliseconds;
    await lp.submitAnswer(
      correct,
      timeTakenMs: ms,
      userAnswer: correct ? 'Got it' : 'Didn\'t know',
      correctAnswer: word?.meaningVn ?? '',
      prompt: word?.word ?? '',
      mode: 'flashcard',
      advance: false,
    );

    // Wait a brief moment to match the individual screen's timing
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    final total = lp.session?.words.length ?? 1;
    final current = lp.session?.currentIndex ?? 0;
    if (current >= total - 1) {
      final result = await lp.completeSession();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/result', arguments: result);
      }
    } else {
      lp.goToNextWord();
      _nextMode();
    }
  }

  Future<void> _selectOption(bool correct) async {
    if (_submitted) return;
    setState(() => _submitted = true);
    final lp = context.read<LearnProvider>();
    final word = lp.currentWord!;
    final ms = DateTime.now().difference(_wordStartTime).inMilliseconds;
    final mode = _mode == _MixedMode.fillBlank ? 'fill_blank' : 'reverse_recall';
    final prompt = _mode == _MixedMode.fillBlank
        ? (word.example.isNotEmpty ? word.example.replaceAll(word.word, '_______') : 'The _______ means: ${word.meaningVn}')
        : word.meaningVn;
    
    await lp.submitAnswer(
      correct,
      timeTakenMs: ms,
      userAnswer: correct ? 'Correct answer' : 'Incorrect answer',
      correctAnswer: 'Correct',
      prompt: prompt,
      mode: mode,
      advance: false,
    );

    // Wait a brief moment to match the individual screen's timing
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    final total = lp.session?.words.length ?? 1;
    final current = lp.session?.currentIndex ?? 0;
    if (current >= total - 1) {
      final result = await lp.completeSession();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/result', arguments: result);
      }
    } else {
      lp.goToNextWord();
      _nextMode();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lp   = context.watch<LearnProvider>();
    final word = lp.currentWord;
    if (word == null) return const SizedBox.shrink();

    final total   = lp.session?.words.length ?? 1;
    final current = lp.session?.currentIndex ?? 0;

    final favP = context.watch<FavoriteProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: LingoAppBar(
        title: '${current + 1} / $total',
        showStreak: false,
        actions: [
          IconButton(
            icon: Icon(
              favP.isFavorite(word.id) ? Icons.favorite : Icons.favorite_border,
              color: favP.isFavorite(word.id) ? Colors.pinkAccent : AppColors.textSecondary,
            ),
            onPressed: () => favP.toggleFavorite(word),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              children: [
                AppProgressBar(value: current / total, color: AppColors.error),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    _modeLabel(_mode),
                    style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Flashcard sub-mode ──────────────────────────────────
                if (_mode == _MixedMode.flashcard) ...[
                  FlashcardScreen(
                    key: ValueKey('fc_${word.id}'),
                    isMixedMode: true,
                    onAnswer: _answer,
                  ),
                ],

                // ── Fill in the Blank sub-mode ──────────────────────────
                if (_mode == _MixedMode.fillBlank) ...[
                  MultipleChoicePracticeScreen(
                    key: ValueKey('fb_${word.id}'),
                    isMixedMode: true,
                    overrideMode: 'fill_blank',
                    onAnswer: _selectOption,
                  ),
                ],

                // ── Reverse Recall sub-mode ─────────────────────────────
                if (_mode == _MixedMode.reverse) ...[
                  MultipleChoicePracticeScreen(
                    key: ValueKey('rr_${word.id}'),
                    isMixedMode: true,
                    overrideMode: 'reverse_recall',
                    onAnswer: _selectOption,
                  ),
                ],

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _modeLabel(_MixedMode m) {
    switch (m) {
      case _MixedMode.flashcard: return '🃏 Flashcard';
      case _MixedMode.fillBlank: return '✏️ Fill in the Blank';
      case _MixedMode.reverse:   return '🔄 Reverse Recall';
    }
  }
}
