// Listening Recall Screen — shows word pronunciation, user picks meaning
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../providers/learn_provider.dart';
import '../../core/constants/app_constants.dart';
import '../widgets/shared_widgets.dart';

class ListeningScreen extends StatefulWidget {
  const ListeningScreen({super.key});
  @override
  State<ListeningScreen> createState() => _ListeningScreenState();
}

class _ListeningScreenState extends State<ListeningScreen>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<String> _options = [];
  String? _selected;
  bool _submitted = false;
  bool _revealed  = false;
  final _startTime = DateTime.now();
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900),
        lowerBound: 0.9, upperBound: 1.1)
      ..repeat(reverse: true);
    _buildOptions();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _buildOptions() {
    final lp = context.read<LearnProvider>();
    final word = lp.currentWord;
    if (word == null) return;

    // Play audio automatically
    if (word.audioUrl.isNotEmpty) {
      _audioPlayer.play(UrlSource(word.audioUrl));
    }

    final allWords = lp.session?.words ?? [];
    final distractors = allWords
        .where((w) => w.meaningVn != word.meaningVn)
        .map((w) => w.meaningVn)
        .toList()..shuffle();
    final opts = [word.meaningVn, ...distractors.take(3)]..shuffle();
    setState(() { _options = opts; _revealed = false; });
  }

  Future<void> _select(String option) async {
    if (_submitted) return;
    setState(() { _selected = option; _submitted = true; });
    final lp    = context.read<LearnProvider>();
    final word  = lp.currentWord!;
    final correct = option == word.meaningVn;
    final ms    = DateTime.now().difference(_startTime).inMilliseconds;

    await Future.delayed(const Duration(milliseconds: 900));
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
          children: [
            AppProgressBar(value: current / total),
            const SizedBox(height: 32),

            // Speaker button
            const Text('WHAT DOES THIS WORD MEAN?', style: AppTextStyles.label),
            const SizedBox(height: 24),

            ScaleTransition(
              scale: _pulseCtrl,
              child: GestureDetector(
                onTap: () {
                  if (word.audioUrl.isNotEmpty) {
                    _audioPlayer.play(UrlSource(word.audioUrl));
                  }
                  setState(() => _revealed = true);
                },
                child: Container(
                  width: 130, height: 130,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0EA5E9), Color(0xFF3B82F6)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: AppColors.info.withOpacity(0.35),
                          blurRadius: 24, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: const Icon(Icons.headphones_rounded, color: Colors.white, size: 56),
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (_revealed)
              Text(word.word,
                  style: const TextStyle(
                    fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.primary))
            else
              Text('Tap the headphones to reveal the word',
                  style: AppTextStyles.bodySmall),

            const SizedBox(height: 32),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('SELECT THE MEANING', style: AppTextStyles.label),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: ListView.separated(
                itemCount: _options.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final opt = _options[i];
                  Color bg = Colors.white;
                  Color border = Colors.grey.shade200;
                  Color textClr = AppColors.textPrimary;

                  if (_submitted && _selected == opt) {
                    final isCorrect = opt == word.meaningVn;
                    bg = isCorrect ? AppColors.success.withOpacity(0.12) : AppColors.error.withOpacity(0.12);
                    border = isCorrect ? AppColors.success : AppColors.error;
                    textClr = isCorrect ? AppColors.success : AppColors.error;
                  } else if (_submitted && opt == word.meaningVn) {
                    bg = AppColors.success.withOpacity(0.12);
                    border = AppColors.success;
                    textClr = AppColors.success;
                  }

                  return GestureDetector(
                    onTap: () => _select(opt),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: border, width: 1.5),
                      ),
                      child: Text(opt,
                          style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15, color: textClr)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
