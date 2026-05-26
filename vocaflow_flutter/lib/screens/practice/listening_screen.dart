// Listening Recall Screen — shows word pronunciation, user picks meaning
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/learn_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../services/tts_service.dart';
import '../widgets/shared_widgets.dart';

class ListeningScreen extends StatefulWidget {
  const ListeningScreen({super.key});
  @override
  State<ListeningScreen> createState() => _ListeningScreenState();
}

class _ListeningScreenState extends State<ListeningScreen>
    with SingleTickerProviderStateMixin {
  final TtsService _tts = TtsService();
  List<String> _options = [];
  String? _selected;
  bool _submitted = false;
  bool _revealed  = false;
  DateTime _wordStartTime = DateTime.now();
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
    _tts.stop();
    super.dispose();
  }

  void _buildOptions() {
    final lp = context.read<LearnProvider>();
    final word = lp.currentWord;
    if (word == null) return;

    // Phát âm thanh tự động khi vừa vào từ mới
    _tts.playWord(word.word, audioUrl: word.audioUrl);

    final allWords = lp.session?.words ?? [];
    final distractors = allWords
        .where((w) => w.meaningVn != word.meaningVn)
        .map((w) => w.meaningVn)
        .toList()..shuffle();
    final opts = [word.meaningVn, ...distractors.take(3)]..shuffle();
    setState(() {
      _options = opts;
      _selected = null;
      _submitted = false;
      _revealed = false; // Reset trạng thái ẩn chữ cho từ mới
    });
    _wordStartTime = DateTime.now();
  }

  // Hàm helper để gọi phát âm thanh dễ dàng
  void _playAudio(String word, String audioUrl) {
    _tts.playWord(word, audioUrl: audioUrl);
  }

  Future<void> _select(String option) async {
    if (_submitted) return;
    setState(() { _selected = option; _submitted = true; });
    final lp    = context.read<LearnProvider>();
    final word  = lp.currentWord!;
    final correct = option == word.meaningVn;
    final ms    = DateTime.now().difference(_wordStartTime).inMilliseconds;

    await lp.submitAnswer(
      correct,
      timeTakenMs: ms,
      userAnswer: option,
      correctAnswer: word.meaningVn,
      prompt: word.word,
      options: _options,
      mode: 'listening',
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          children: [
            AppProgressBar(value: (current + 1) / total),
            const SizedBox(height: 32),

            const Text('WHAT DOES THIS WORD MEAN?', style: AppTextStyles.label),
            const SizedBox(height: 24),

            // NÚT NGHE LẠI (Speaker button)
            ScaleTransition(
              scale: _pulseCtrl,
              child: GestureDetector(
                onTap: () => _playAudio(word.word, word.audioUrl), // Nhấn vào đây để nghe lại thoải mái
                child: Container(
                  width: 120, height: 120,
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
                  child: const Icon(Icons.volume_up_rounded, color: Colors.white, size: 52),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // KHU VỰC HIỂN THỊ TỪ / NÚT SHOW TỪ TÁCH BIỆT
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _revealed
                  ? Text(
                      word.word,
                      key: const ValueKey('word_text'),
                      style: const TextStyle(
                          fontSize: 30, 
                          fontWeight: FontWeight.w800, 
                          color: AppColors.primary,
                          letterSpacing: 0.5,
                      ),
                    )
                  : TextButton.icon(
                      key: const ValueKey('show_button'),
                      onPressed: () => setState(() => _revealed = true),
                      icon: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.textSecondary),
                      label: const Text('Show Word Hint', 
                          style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        backgroundColor: Colors.grey.shade100,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
            ),

            const SizedBox(height: 32),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('SELECT THE MEANING', style: AppTextStyles.label),
            ),
            const SizedBox(height: 12),

            // Danh sách các lựa chọn đáp án nghĩa Tiếng Việt
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
            
            const SizedBox(height: 20),
            
            // Thanh điều hướng Prev / Next bài tập

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
