// Mixed Challenge Screen — randomly picks a mode per word
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/learn_provider.dart';
import '../../core/constants/app_constants.dart';
import '../widgets/shared_widgets.dart';

enum _MixedMode { flashcard, fillBlank, reverse }

class MixedChallengeScreen extends StatefulWidget {
  const MixedChallengeScreen({super.key});
  @override
  State<MixedChallengeScreen> createState() => _MixedChallengeScreenState();
}

class _MixedChallengeScreenState extends State<MixedChallengeScreen> {
  _MixedMode _mode = _MixedMode.flashcard;
  List<String> _options = [];
  String? _selected;
  bool _submitted  = false;
  bool _showBack   = false;
  final _rand      = Random();
  final _startTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _nextMode();
  }

  void _nextMode() {
    final modes = _MixedMode.values;
    _mode = modes[_rand.nextInt(modes.length)];
    _buildOptions();
  }

  void _buildOptions() {
    final lp = context.read<LearnProvider>();
    final word = lp.currentWord;
    if (word == null) return;
    final all = lp.session?.words ?? [];
    final dist = all.where((w) => w.word != word.word).map((w) => w.word).toList()..shuffle();
    final opts = [word.word, ...dist.take(3)]..shuffle();
    setState(() { _options = opts; _selected = null; _submitted = false; _showBack = false; });
  }

  Future<void> _answer(bool correct) async {
    if (_submitted) return;
    setState(() => _submitted = true);
    final ms = DateTime.now().difference(_startTime).inMilliseconds;
    await context.read<LearnProvider>().submitAnswer(correct, timeTakenMs: ms);
    if (!mounted) return;
    final lp = context.read<LearnProvider>();
    if (lp.isSessionComplete) {
      final result = await lp.completeSession();
      Navigator.pushReplacementNamed(context, '/result', arguments: result);
    } else {
      _nextMode();
    }
  }

  Future<void> _selectOption(String opt) async {
    if (_submitted) return;
    setState(() { _selected = opt; _submitted = true; });
    final lp = context.read<LearnProvider>();
    final correct = opt == lp.currentWord!.word;
    await Future.delayed(const Duration(milliseconds: 800));
    await _answer(correct);
  }

  @override
  Widget build(BuildContext context) {
    final lp   = context.watch<LearnProvider>();
    final word = lp.currentWord;
    if (word == null) return const SizedBox.shrink();

    final total   = lp.session?.words.length ?? 1;
    final current = lp.session?.currentIndex ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shuffle_rounded, color: AppColors.primary, size: 18),
            const SizedBox(width: 6),
            Text('$current / $total',
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ],
        ),
      ),
      body: Padding(
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
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _showBack = !_showBack),
                  child: AppCard(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: _showBack
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(word.meaningVn,
                                    style: const TextStyle(
                                      fontSize: 26, fontWeight: FontWeight.w800,
                                      color: AppColors.primary)),
                                const SizedBox(height: 12),
                                Text(word.definitionVn, style: AppTextStyles.bodySmall,
                                    textAlign: TextAlign.center),
                              ],
                            )
                          : Text(word.word,
                              style: const TextStyle(
                                fontSize: 40, fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (!_showBack)
                Text('Tap to flip', style: AppTextStyles.bodySmall)
              else
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _submitted ? null : () => _answer(false),
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(color: AppColors.error.withOpacity(0.3)),
                          ),
                          child: const Center(child: Icon(Icons.close_rounded, color: AppColors.error, size: 28)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: _submitted ? null : () => _answer(true),
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(color: AppColors.success.withOpacity(0.3)),
                          ),
                          child: const Center(child: Icon(Icons.check_rounded, color: AppColors.success, size: 28)),
                        ),
                      ),
                    ),
                  ],
                ),
            ],

            // ── MCQ sub-modes ───────────────────────────────────────
            if (_mode != _MixedMode.flashcard) ...[
              AppCard(
                padding: const EdgeInsets.all(20),
                child: Text(
                  _mode == _MixedMode.fillBlank
                      ? 'Meaning: ${word.meaningVn}'
                      : word.meaningVn,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('SELECT THE CORRECT WORD', style: AppTextStyles.label),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.5,
                children: _options.map((opt) {
                  Color bg = Colors.white;
                  Color border = Colors.grey.shade200;
                  Color textClr = AppColors.textPrimary;
                  if (_submitted && _selected == opt) {
                    final c = opt == word.word;
                    bg = c ? AppColors.success.withOpacity(0.12) : AppColors.error.withOpacity(0.12);
                    border = c ? AppColors.success : AppColors.error;
                    textClr = c ? AppColors.success : AppColors.error;
                  } else if (_submitted && opt == word.word) {
                    bg = AppColors.success.withOpacity(0.12);
                    border = AppColors.success;
                    textClr = AppColors.success;
                  }
                  return GestureDetector(
                    onTap: () => _selectOption(opt),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: border, width: 1.5),
                      ),
                      child: Center(
                        child: Text(opt,
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: textClr)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 24),
          ],
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
