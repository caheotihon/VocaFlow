// Typing Challenge Screen
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/learn_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../core/constants/app_constants.dart';
import '../widgets/shared_widgets.dart';

class TypingScreen extends StatefulWidget {
  const TypingScreen({super.key});
  @override
  State<TypingScreen> createState() => _TypingScreenState();
}

class _TypingScreenState extends State<TypingScreen> {
  final _ctrl       = TextEditingController();
  final _focusNode  = FocusNode();
  bool? _isCorrect;
  bool _submitted   = false;
  DateTime _startTime  = DateTime.now();
  Timer? _nextTimer;

  @override
  void dispose() {
    _nextTimer?.cancel();
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    if (_submitted) return;
    final lp   = context.read<LearnProvider>();
    final word = lp.currentWord!;
    final answer = _ctrl.text.trim().toLowerCase();
    final correct = answer == word.word.toLowerCase();

    setState(() { _isCorrect = correct; _submitted = true; });

    final ms = DateTime.now().difference(_startTime).inMilliseconds;
    lp.submitAnswer(
      correct,
      timeTakenMs: ms,
      userAnswer: _ctrl.text.trim(),
      correctAnswer: word.word,
      prompt: word.example.isNotEmpty ? word.example.replaceAll(word.word, '___') : 'Meaning: ${word.meaningVn}',
      mode: 'typing',
      advance: false,
    );

    if (correct) {
      _nextTimer = Timer(const Duration(milliseconds: 1000), () {
        if (mounted) _goToNext();
      });
    }
  }

  Future<void> _goToNext() async {
    final lp = context.read<LearnProvider>();
    lp.nextWord();
    if (lp.isSessionComplete) {
      final result = await lp.completeSession();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/result', arguments: result);
      }
    } else {
      _ctrl.clear();
      setState(() { _isCorrect = null; _submitted = false; _startTime = DateTime.now(); });
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lp   = context.watch<LearnProvider>();
    final word = lp.currentWord;
    if (word == null) return const SizedBox.shrink();

    final total   = lp.session?.words.length ?? 1;
    final current = (lp.session?.currentIndex ?? 0);

    Color borderColor = AppColors.textHint;
    if (_isCorrect == true)  borderColor = AppColors.success;
    if (_isCorrect == false) borderColor = AppColors.error;

    final favP = context.watch<FavoriteProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppProgressBar(value: current / total),
                          const SizedBox(height: 28),

                          // Definition card
                          AppCard(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(AppRadius.full),
                                  ),
                                  child: Text(word.partOfSpeech,
                                      style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                                ),
                                const SizedBox(height: 14),
                                Text('Meaning: ${word.meaningVn}',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                                if (word.definitionVn.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(word.definitionVn, style: AppTextStyles.bodySmall),
                                ],
                                if (word.example.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(AppRadius.sm),
                                    ),
                                    child: Text(
                                      word.example.replaceAll(word.word, '___'),
                                      style: AppTextStyles.body.copyWith(fontStyle: FontStyle.italic),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          const Text('TYPE THE WORD', style: AppTextStyles.label),
                          const SizedBox(height: 10),

                          TextField(
                            controller: _ctrl,
                            focusNode: _focusNode,
                            autofocus: true,
                            enabled: !_submitted,
                            onSubmitted: (_) => _submitted ? _goToNext() : _submit(),
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 1),
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              hintText: 'Type your answer...',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.lg),
                                borderSide: BorderSide(color: borderColor, width: 2),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.lg),
                                borderSide: BorderSide(color: borderColor, width: 2),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.lg),
                                borderSide: BorderSide(color: borderColor, width: 2),
                              ),
                              suffixIcon: _submitted
                                  ? Icon(
                                      _isCorrect! ? Icons.check_circle : Icons.cancel,
                                      color: _isCorrect! ? AppColors.success : AppColors.error,
                                      size: 28,
                                    )
                                  : null,
                            ),
                          ),

                          if (_submitted && _isCorrect == false) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.lightbulb_outline, color: AppColors.error, size: 18),
                                  const SizedBox(width: 8),
                                  Text('Correct: ${word.word}',
                                      style: const TextStyle(
                                          color: AppColors.error, fontWeight: FontWeight.w700, fontSize: 16)),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),
                          if (!_submitted || (_submitted && _isCorrect == false))
                            Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 340),
                                child: GradientButton(
                                  text: _submitted ? 'Continue' : 'Check Answer',
                                  onTap: _submitted ? _goToNext : _submit,
                                  icon: _submitted ? Icons.arrow_forward_rounded : Icons.check_rounded,
                                ),
                              ),
                            ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
