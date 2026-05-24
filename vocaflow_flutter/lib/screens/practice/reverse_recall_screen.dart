// Reverse Recall Screen — see meaning, recall the word
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/learn_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../core/constants/app_constants.dart';
import '../widgets/shared_widgets.dart';

class ReverseRecallScreen extends StatefulWidget {
  final bool isMixedMode;
  final Function(bool)? onAnswer;

  const ReverseRecallScreen({
    super.key,
    this.isMixedMode = false,
    this.onAnswer,
  });

  @override
  State<ReverseRecallScreen> createState() => _ReverseRecallScreenState();
}

class _ReverseRecallScreenState extends State<ReverseRecallScreen> {
  List<String> _options = [];
  String? _selected;
  bool _submitted = false;
  DateTime _wordStartTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _buildOptions();
  }

  void _buildOptions() {
    final lp = context.read<LearnProvider>();
    final word = lp.currentWord;
    if (word == null) return;
    final allWords = lp.session?.words.map((w) => w.word).toList() ?? [];
    final distractors = allWords.where((w) => w != word.word).toList()..shuffle();
    final opts = [word.word, ...distractors.take(3)]..shuffle();
    setState(() {
      _options = opts;
      _selected = null;
      _submitted = false;
    });
    _wordStartTime = DateTime.now();
  }

  Future<void> _select(String option) async {
    if (_submitted) return;
    setState(() { _selected = option; _submitted = true; });
    final lp    = context.read<LearnProvider>();
    final word  = lp.currentWord!;
    final correct = option == word.word;

    if (widget.isMixedMode) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      if (widget.onAnswer != null) {
        widget.onAnswer!(correct);
      }
      return;
    }

    final ms    = DateTime.now().difference(_wordStartTime).inMilliseconds;
    await lp.submitAnswer(
      correct,
      timeTakenMs: ms,
      userAnswer: option,
      correctAnswer: word.word,
      prompt: word.meaningVn,
      options: _options,
      mode: 'reverse_recall',
      advance: false,
    );

    await Future.delayed(const Duration(seconds: 1));
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
      _buildOptions();
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

    Widget content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          if (!widget.isMixedMode) ...[
            AppProgressBar(value: current / total),
            const SizedBox(height: 28),
          ],

          // Definition card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: AppColors.success.withOpacity(0.3),
                    blurRadius: 20, offset: const Offset(0, 6)),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: const Text('What is this word?',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 20),
                Text(word.meaningVn,
                    style: const TextStyle(
                      fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white),
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Text(word.definitionVn,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8), fontSize: 14, height: 1.4),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
          const SizedBox(height: 28),

          const Align(
            alignment: Alignment.centerLeft,
            child: Text('CHOOSE THE CORRECT WORD', style: AppTextStyles.label),
          ),
          const SizedBox(height: 14),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2,
            children: _options.map((opt) {
              Color bg      = Colors.white;
              Color border  = Colors.grey.shade200;
              Color textClr = AppColors.textPrimary;

              if (_submitted && _selected == opt) {
                final isCorrect = opt == word.word;
                bg = isCorrect ? AppColors.success.withOpacity(0.12) : AppColors.error.withOpacity(0.12);
                border = isCorrect ? AppColors.success : AppColors.error;
                textClr = isCorrect ? AppColors.success : AppColors.error;
              } else if (_submitted && opt == word.word) {
                bg = AppColors.success.withOpacity(0.12);
                border = AppColors.success;
                textClr = AppColors.success;
              }

              return GestureDetector(
                onTap: () => _select(opt),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: border, width: 1.5),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04),
                          blurRadius: 6, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Center(
                    child: Text(opt,
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16, color: textClr)),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const SizedBox(height: 12),
        ],
      ),
    );

    if (widget.isMixedMode) {
      return content;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
        centerTitle: true,
        title: Text('$current / $total',
            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
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
          child: content,
        ),
      ),
    );
  }
}
