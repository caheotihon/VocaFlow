// AI Speech Practice Screen — grades pronunciation of example sentences with visual highlights
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import '../../providers/learn_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../services/tts_service.dart';
import '../widgets/shared_widgets.dart';

class SpeechPracticeScreen extends StatefulWidget {
  const SpeechPracticeScreen({super.key});

  @override
  State<SpeechPracticeScreen> createState() => _SpeechPracticeScreenState();
}

class _SpeechPracticeScreenState extends State<SpeechPracticeScreen>
    with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final TtsService _tts = TtsService();

  bool _isAvailable = false;
  bool _isListening = false;
  String _transcribedText = "";
  double _score = -1.0; // -1 means not tested yet
  bool _submitted = false;
  bool _answering = false;
  DateTime _startTime = DateTime.now();

  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    try {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            setState(() {
              _isListening = false;
            });
            if (_transcribedText.isNotEmpty) {
              _evaluateSpeech();
            }
          }
        },
        onError: (val) {
          print('❌ [STT Error]: $val');
          setState(() {
            _isListening = false;
          });
        },
      );
      if (mounted) {
        setState(() {
          _isAvailable = available;
        });
      }
    } catch (e) {
      print('❌ [STT Init Exception]: $e');
    }
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() {
        _isListening = false;
      });
    } else {
      if (!_isAvailable) {
        await _initSpeech();
        if (!_isAvailable) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Speech recognition is not available.')),
          );
          return;
        }
      }

      setState(() {
        _isListening = true;
        _transcribedText = "";
        _score = -1.0;
        _submitted = false;
      });

      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          setState(() {
            _transcribedText = result.recognizedWords;
          });
        },
        localeId: 'en_US',
        listenFor: const Duration(seconds: 8),
        pauseFor: const Duration(seconds: 3),
      );
    }
  }

  void _evaluateSpeech() {
    final lp = context.read<LearnProvider>();
    final word = lp.currentWord;
    if (word == null) return;

    // We grade pronunciation based on the example sentence if available, otherwise the word itself
    final targetText = word.example.isNotEmpty ? word.example : word.word;

    final cleanTarget = targetText.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').trim();
    final cleanTranscribed = _transcribedText.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').trim();

    if (cleanTranscribed.isEmpty) {
      setState(() {
        _score = 0.0;
        _submitted = true;
      });
      return;
    }

    final distance = _levenshtein(cleanTarget, cleanTranscribed);
    final maxLength = math.max(cleanTarget.length, cleanTranscribed.length);
    double ratio = 1.0 - (distance / maxLength);
    double scorePct = (ratio * 100).clamp(0.0, 100.0);

    // Boost scores if exactly matching or contains clean segments to improve learner confidence
    if (cleanTranscribed == cleanTarget) {
      scorePct = 100.0;
    } else if (cleanTarget.contains(cleanTranscribed) || cleanTranscribed.contains(cleanTarget)) {
      scorePct = math.max(scorePct, 80.0);
    }

    setState(() {
      _score = scorePct;
      _submitted = true;
    });

    // Auto submit learning results to the backend
    final correct = scorePct >= 70; // 70%+ is counted as correct
    final ms = DateTime.now().difference(_startTime).inMilliseconds;
    lp.submitAnswer(
      correct,
      timeTakenMs: ms,
      userAnswer: _transcribedText,
      correctAnswer: targetText,
      prompt: targetText,
      mode: 'speech',
      advance: false,
    );
  }

  int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<int> v0 = List<int>.filled(t.length + 1, 0);
    List<int> v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i < v0.length; i++) {
      v0[i] = i;
    }

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < t.length; j++) {
        int cost = (s[i] == t[j]) ? 0 : 1;
        v1[j + 1] = math.min(
          v1[j] + 1,
          math.min(v0[j + 1] + 1, v0[j] + cost),
        );
      }
      for (int j = 0; j < v0.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v0[t.length];
  }

  Future<void> _goToNext() async {
    if (_answering) return;
    setState(() => _answering = true);

    final lp = context.read<LearnProvider>();
    // If not submitted yet, submit as incorrect by default before moving next
    if (!_submitted) {
      final ms = DateTime.now().difference(_startTime).inMilliseconds;
      final word = lp.currentWord;
      final targetText = word != null ? (word.example.isNotEmpty ? word.example : word.word) : '';
      await lp.submitAnswer(
        false,
        timeTakenMs: ms,
        userAnswer: '',
        correctAnswer: targetText,
        prompt: targetText,
        mode: 'speech',
        advance: false,
      );
    }

    lp.nextWord();
    if (lp.isSessionComplete) {
      final result = await lp.completeSession();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/result', arguments: result);
      }
    } else {
      setState(() {
        _transcribedText = "";
        _score = -1.0;
        _submitted = false;
        _answering = false;
        _startTime = DateTime.now();
      });
    }
  }

  List<Widget> _buildHighlightedSentence(String targetSentence) {
    if (_transcribedText.isEmpty) {
      // If nothing has been spoken yet, render all words in normal color (textPrimary)
      return targetSentence.split(' ').map((word) {
        return Text(
          '$word ',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
        );
      }).toList();
    }

    // Preprocess target and spoken text
    String clean(String s) => s.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').trim();
    
    final cleanSpoken = clean(_transcribedText);
    final spokenWordsList = cleanSpoken.split(' ').where((w) => w.isNotEmpty).toList();

    final originalWords = targetSentence.split(' ');
    final List<Widget> spans = [];

    for (final word in originalWords) {
      final cleanWord = clean(word);
      final isCorrect = spokenWordsList.contains(cleanWord);

      spans.add(
        Text(
          '$word ',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: isCorrect ? AppColors.success : AppColors.error,
          ),
        ),
      );
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LearnProvider>();
    final word = lp.currentWord;
    if (word == null) return const SizedBox.shrink();

    final total = lp.session?.words.length ?? 1;
    final current = lp.session?.currentIndex ?? 0;
    final progress = current / total;

    final favP = context.watch<FavoriteProvider>();
    final targetSentence = word.example.isNotEmpty ? word.example : word.word;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: LingoAppBar(
        title: '${current + 1} / $total',
        showStreak: false,
        leading: BackButton(
          color: AppColors.textPrimary,
          onPressed: () => _showExitDialog(context),
        ),
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
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AppProgressBar(value: progress),
                  const SizedBox(height: 24),

                  // Top Word Title Card
                  AppCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              child: Text(
                                word.partOfSpeech.toUpperCase(),
                                style: const TextStyle(
                                    color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (word.pronunciation.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text(
                                '/${word.pronunciation}/',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          word.word,
                          style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          word.meaningVn,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Example Sentence & Speaking Diff Area
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('SPEAK THIS SENTENCE', style: AppTextStyles.label),
                  ),
                  const SizedBox(height: 10),

                  AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Highlighted Word Diff Wrap
                        Wrap(
                          children: _buildHighlightedSentence(targetSentence),
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => _tts.speak(targetSentence),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.volume_up_rounded, color: AppColors.primary, size: 22),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                word.exampleVn.isNotEmpty ? word.exampleVn : 'Nghe phát âm chuẩn AI',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                    fontStyle: word.exampleVn.isNotEmpty ? FontStyle.italic : FontStyle.normal),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Microphone controller
                  GestureDetector(
                    onTap: _toggleListening,
                    child: AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (context, child) {
                        double value = _pulseCtrl.value;
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isListening
                                ? Colors.red.withOpacity(0.1 + (value * 0.15))
                                : AppColors.primary.withOpacity(0.08),
                          ),
                          child: Container(
                            width: 82,
                            height: 82,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isListening ? Colors.red : AppColors.primary,
                              boxShadow: [
                                BoxShadow(
                                  color: (_isListening ? Colors.red : AppColors.primary).withOpacity(0.35),
                                  blurRadius: 16 + (value * 12),
                                  spreadRadius: value * 4,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Icon(
                              _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isListening ? 'Listening... Speak now!' : 'Tap the mic to record',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _isListening ? Colors.red : AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),

                  // Grading Result
                  if (_submitted) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: (_score >= 70 ? AppColors.success : AppColors.error).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: (_score >= 70 ? AppColors.success : AppColors.error).withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _score >= 70 ? Icons.check_circle_rounded : Icons.cancel_rounded,
                            color: _score >= 70 ? AppColors.success : AppColors.error,
                            size: 26,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pronunciation Score: ${_score.round()}% Match',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: _score >= 70 ? AppColors.success : AppColors.error),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _score >= 70 ? 'Amazing job! Kept it up! 🎉' : 'A bit off. Try practicing again! 💪',
                                  style: TextStyle(
                                      fontSize: 12, color: _score >= 70 ? AppColors.success : AppColors.error),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Action Buttons
                  Row(
                    children: [
                      if (_submitted && _score < 70) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _toggleListening,
                            icon: const Icon(Icons.replay_rounded, size: 20),
                            label: const Text('Try Again'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: GradientButton(
                          text: _submitted ? 'Continue' : 'Skip Word',
                          onTap: _goToNext,
                          isLoading: _answering,
                          icon: Icons.arrow_forward_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
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
