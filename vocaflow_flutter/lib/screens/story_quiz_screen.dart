import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:audioplayers/audioplayers.dart';
import '../providers/story_provider.dart';
import '../models/story_model.dart';
import '../models/word_model.dart';
import '../core/constants/app_constants.dart';
import 'widgets/shared_widgets.dart';
import 'story_view_screen.dart';

class StoryQuizScreen extends StatefulWidget {
  const StoryQuizScreen({super.key});

  @override
  State<StoryQuizScreen> createState() => _StoryQuizScreenState();
}

class _StoryQuizScreenState extends State<StoryQuizScreen> {
  int _currentQuestionIndex = 0;
  int? _selectedOptionIndex;
  bool _isAnswered = false;
  int _correctAnswersCount = 0;
  bool _isCompleting = false;

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playPronunciation(String audioUrl) async {
    if (audioUrl.isEmpty) return;
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(audioUrl));
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  void _showWordDetailBottomSheet(BuildContext context, WordModel word) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).padding.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            word.word,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Text(
                              word.partOfSpeech.toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (word.audioUrl.isNotEmpty)
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.volume_up_rounded, color: AppColors.primary, size: 28),
                          onPressed: () => _playPronunciation(word.audioUrl),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (word.pronunciation.isNotEmpty) ...[
                  Text(
                    '/${word.pronunciation}/',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                const Divider(color: Colors.black12),
                const SizedBox(height: 12),
                const Text('Meaning:', style: AppTextStyles.label),
                const SizedBox(height: 4),
                Text(
                  word.meaningVn,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                if (word.definitionEn.isNotEmpty || word.definitionVn.isNotEmpty) ...[
                  const Text('Definition:', style: AppTextStyles.label),
                  const SizedBox(height: 4),
                  Text(
                    word.definitionEn.isNotEmpty ? word.definitionEn : word.definitionVn,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (word.example.isNotEmpty) ...[
                  const Text('Example:', style: AppTextStyles.label),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          word.example,
                          style: const TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textPrimary,
                            height: 1.4,
                          ),
                        ),
                        if (word.exampleVn.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            word.exampleVn,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  List<InlineSpan> _buildStorySpans(String content, List<WordModel> words, BuildContext context) {
    if (words.isEmpty) {
      return [
        TextSpan(
          text: content,
          style: const TextStyle(fontSize: 17, fontFamily: 'Georgia', height: 1.7, color: AppColors.textPrimary),
        )
      ];
    }

    final sortedWords = List<WordModel>.from(words);
    sortedWords.sort((a, b) => b.word.length.compareTo(a.word.length));

    final escapedWords = sortedWords.map((w) => RegExp.escape(w.word)).join('|');
    final regExp = RegExp('\\b($escapedWords)\\b', caseSensitive: false);

    final List<InlineSpan> spans = [];
    int start = 0;

    content.splitMapJoin(
      regExp,
      onMatch: (Match match) {
        final matchedText = match[0]!;
        final wordModel = sortedWords.firstWhere(
          (w) => w.word.toLowerCase() == matchedText.toLowerCase(),
          orElse: () => sortedWords.first,
        );

        final preText = content.substring(start, match.start);
        if (preText.isNotEmpty) {
          spans.add(TextSpan(
            text: preText,
            style: const TextStyle(
              fontSize: 17,
              fontFamily: 'Georgia',
              height: 1.7,
              color: AppColors.textPrimary,
            ),
          ));
        }

        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: HoverWordPopup(
            word: wordModel,
            matchedText: matchedText,
            onTap: () {
              _showWordDetailBottomSheet(context, wordModel);
            },
          ),
        ));

        start = match.end;
        return '';
      },
      onNonMatch: (String nonMatch) {
        return '';
      },
    );

    if (start < content.length) {
      spans.add(TextSpan(
        text: content.substring(start),
        style: const TextStyle(
          fontSize: 17,
          fontFamily: 'Georgia',
          height: 1.7,
          color: AppColors.textPrimary,
        ),
      ));
    }

    return spans;
  }

  void _selectOption(int index, int correctIndex) {
    if (_isAnswered) return;
    setState(() {
      _selectedOptionIndex = index;
      _isAnswered = true;
      if (index == correctIndex) {
        _correctAnswersCount++;
      }
    });
  }

  Future<void> _handleNext(List<StoryQuizModel> quizList, String storyId, bool alreadyCompleted) async {
    if (_currentQuestionIndex < quizList.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedOptionIndex = null;
        _isAnswered = false;
      });
    } else {
      // Quiz completed!
      if (alreadyCompleted) {
        // Just go back to home screen
        Navigator.popUntil(context, ModalRoute.withName('/home'));
      } else {
        // Complete the quiz on backend and award +30 XP!
        setState(() => _isCompleting = true);
        final storyP = context.read<StoryProvider>();
        final success = await storyP.finishStoryQuiz(storyId);
        setState(() => _isCompleting = false);

        if (success && mounted) {
          _showCelebrationDialog(context, score: _correctAnswersCount, total: quizList.length);
        } else if (mounted) {
          // Fallback if network fails, still show congratulations but friendly warning
          _showCelebrationDialog(context, errorOccurred: true, score: _correctAnswersCount, total: quizList.length);
        }
      }
    }
  }

  void _showCelebrationDialog(BuildContext context, {bool errorOccurred = false, int score = 0, int total = 0}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated trophy
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.amber.shade800,
                    size: 72,
                  ),
                )
                    .animate()
                    .scale(duration: 500.ms, curve: Curves.elasticOut)
                    .shake(duration: 800.ms, hz: 4),
                const SizedBox(height: 24),
                const Text(
                  'Comprehension Master! 🎉',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  errorOccurred
                      ? 'You successfully read the story and finished the quiz! (Score: $score/$total)'
                      : 'You successfully read the AI story and answered $score/$total reading comprehension questions correctly!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 24),
                
                // XP Bonus Card
                if (!errorOccurred)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('⚡', style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 8),
                        const Text(
                          '+30 XP AI Story Bonus',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate(delay: 300.ms)
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad),
                
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.popUntil(context, ModalRoute.withName('/home')); // Back to dashboard
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Awesome, Keep Learning! 🚀',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storyP = context.watch<StoryProvider>();
    final story = storyP.currentStory;

    if (story == null) {
      return const Scaffold(
        appBar: LingoAppBar(title: 'Comprehension Quiz', showStreak: false),
        body: Center(child: Text('No story loaded')),
      );
    }

    final quizList = story.quiz;
    if (quizList.isEmpty) {
      return const Scaffold(
        appBar: LingoAppBar(title: 'Comprehension Quiz', showStreak: false),
        body: Center(child: Text('No questions available for this story.')),
      );
    }

    final quiz = quizList[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / quizList.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const LingoAppBar(
        title: 'Comprehension Quiz',
        showStreak: false,
      ),
      body: _isCompleting
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                // Top Half: Scrollable Story Box
                Container(
                  height: MediaQuery.of(context).size.height * 0.35, // 35% of screen height
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDFBF7), // Warm premium paper background
                    border: Border(
                      bottom: BorderSide(color: Colors.black12, width: 1.5),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          story.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                            fontFamily: 'Georgia',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Refer back to the text to answer the questions below',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Divider(height: 1, color: Colors.black12),
                        const SizedBox(height: 16),
                        RichText(
                          text: TextSpan(
                            children: _buildStorySpans(story.content, story.words, context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Half: Scrollable Quiz Box
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Progress indicator
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(AppRadius.full),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 8,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${_currentQuestionIndex + 1} / ${quizList.length}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Question Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(color: Colors.grey.shade100),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.help_outline_rounded, color: AppColors.primary, size: 20),
                                  SizedBox(width: 6),
                                  Text(
                                    'QUESTION',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                quiz.question,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Options List
                        ...List.generate(quiz.options.length, (idx) {
                          final option = quiz.options[idx];
                          final isSelected = _selectedOptionIndex == idx;
                          final isCorrect = idx == quiz.answerIndex;

                          Color cardColor = Colors.white;
                          Color borderColor = Colors.grey.shade200;
                          Widget? trailingIcon;

                          if (_isAnswered) {
                            if (isCorrect) {
                              cardColor = AppColors.success.withOpacity(0.08);
                              borderColor = AppColors.success.withOpacity(0.4);
                              trailingIcon = const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22);
                            } else if (isSelected) {
                              cardColor = AppColors.error.withOpacity(0.08);
                              borderColor = AppColors.error.withOpacity(0.4);
                              trailingIcon = const Icon(Icons.cancel_rounded, color: AppColors.error, size: 22);
                            }
                          } else if (isSelected) {
                            borderColor = AppColors.primary;
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(
                                color: borderColor,
                                width: isSelected || (_isAnswered && isCorrect) ? 2 : 1,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                              leading: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.grey.shade100,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  String.fromCharCode(65 + idx), // A, B, C, D
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              title: Text(
                                option,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                  fontSize: 14,
                                ),
                              ),
                              trailing: trailingIcon,
                              onTap: () => _selectOption(idx, quiz.answerIndex),
                            ),
                          );
                        }),

                        const SizedBox(height: 12),

                        // Explanation Block
                        if (_isAnswered)
                          Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(color: Colors.black12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.info_outline_rounded, color: AppColors.textSecondary, size: 18),
                                    SizedBox(width: 6),
                                    Text(
                                      'EXPLANATION',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  quiz.explanation,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          )
                              .animate()
                              .fadeIn(duration: 300.ms)
                              .slideY(begin: 0.1, end: 0, curve: Curves.easeOut),

                        // Next Button
                        if (_isAnswered)
                          ElevatedButton(
                            onPressed: () => _handleNext(quizList, story.id, story.isCompleted),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 54),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.lg),
                              ),
                              elevation: 2,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _currentQuestionIndex == quizList.length - 1
                                      ? 'Finish & Claim Bonus'
                                      : 'Next Question',
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded, size: 20),
                              ],
                            ),
                          )
                              .animate()
                              .fadeIn(duration: 400.ms)
                              .scale(
                                begin: const Offset(0.95, 0.95),
                                end: const Offset(1, 1),
                                curve: Curves.elasticOut,
                              ),

                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
