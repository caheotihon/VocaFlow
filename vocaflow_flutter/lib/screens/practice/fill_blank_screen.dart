// Fill in the Blank Screen
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/learn_provider.dart';
import '../../core/constants/app_constants.dart';
import '../widgets/shared_widgets.dart';

class FillBlankScreen extends StatefulWidget {
  const FillBlankScreen({super.key});
  @override
  State<FillBlankScreen> createState() => _FillBlankScreenState();
}

class _FillBlankScreenState extends State<FillBlankScreen> {
  List<String> _options = [];
  String? _selected;
  bool _submitted = false;
  final _startTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _buildOptions();
  }

  void _buildOptions() {
    final lp   = context.read<LearnProvider>();
    final word = lp.currentWord;
    if (word == null) return;

    final correct = word.word;
    final allWords = lp.session?.words.map((w) => w.word).toList() ?? [];
    final distractors = allWords.where((w) => w != correct).toList()..shuffle();
    final opts = [correct, ...distractors.take(3)]..shuffle();

    setState(() => _options = opts);
  }

  Future<void> _select(String option) async {
    if (_submitted) return;
    setState(() { _selected = option; _submitted = true; });

    final lp     = context.read<LearnProvider>();
    final word   = lp.currentWord!;
    final correct = option == word.word;
    final ms     = DateTime.now().difference(_startTime).inMilliseconds;

    await Future.delayed(const Duration(milliseconds: 1000));
    await lp.submitAnswer(correct, timeTakenMs: ms);

    if (!mounted) return;
    if (lp.isSessionComplete) {
      final result = await lp.completeSession();
      Navigator.pushReplacementNamed(context, '/result', arguments: result);
    } else {
      setState(() { _selected = null; _submitted = false; });
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
    final sentence = word.example.isNotEmpty
        ? word.example.replaceAll(word.word, '_______')
        : 'The _______ means: ${word.meaningVn}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
        centerTitle: true,
        title: Text('$current / $total',
            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppProgressBar(value: current / total),
            const SizedBox(height: 28),

            // Instruction
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_note_rounded, color: AppColors.warning, size: 16),
                  SizedBox(width: 6),
                  Text('Fill in the Blank',
                      style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.w600, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Sentence card
            AppCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('COMPLETE THE SENTENCE', style: AppTextStyles.label),
                  const SizedBox(height: 12),
                  Text(sentence,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.5)),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 10),
                  Text('Meaning: ${word.meaningVn}',
                      style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Options grid
            const Text('SELECT THE CORRECT WORD', style: AppTextStyles.label),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.5,
              children: _options.map((opt) {
                Color bg      = Colors.white;
                Color border  = Colors.grey.shade200;
                Color textClr = AppColors.textPrimary;

                if (_submitted && _selected == opt) {
                  final isCorrect = opt == word.word;
                  bg      = isCorrect ? AppColors.success.withOpacity(0.12) : AppColors.error.withOpacity(0.12);
                  border  = isCorrect ? AppColors.success : AppColors.error;
                  textClr = isCorrect ? AppColors.success : AppColors.error;
                } else if (_submitted && opt == word.word) {
                  bg      = AppColors.success.withOpacity(0.12);
                  border  = AppColors.success;
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
                    ),
                    child: Center(
                      child: Text(opt,
                          style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15, color: textClr)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
