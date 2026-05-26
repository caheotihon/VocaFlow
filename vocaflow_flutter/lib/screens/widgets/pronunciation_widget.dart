// Pronunciation practice widget using Speech-to-Text and TTS
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import '../../core/constants/app_constants.dart';
import '../../services/tts_service.dart';

class PronunciationWidget extends StatefulWidget {
  final String targetWord;
  final String audioUrl;

  const PronunciationWidget({
    super.key,
    required this.targetWord,
    this.audioUrl = '',
  });

  @override
  State<PronunciationWidget> createState() => _PronunciationWidgetState();
}

class _PronunciationWidgetState extends State<PronunciationWidget>
    with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final TtsService _tts = TtsService();

  bool _isAvailable = false;
  bool _isListening = false;
  String _transcribedText = "";
  double _score = -1.0; // -1 means not tested yet
  String _feedbackMessage = "";
  Color _feedbackColor = AppColors.textSecondary;

  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
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
              if (_pulseCtrl.isAnimating) _pulseCtrl.stop();
            });
            if (_transcribedText.isNotEmpty) {
              _evaluatePronunciation();
            }
          }
        },
        onError: (val) {
          print('❌ [STT Error]: $val');
          setState(() {
            _isListening = false;
            _pulseCtrl.stop();
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
        _pulseCtrl.stop();
      });
    } else {
      if (!_isAvailable) {
        await _initSpeech();
        if (!_isAvailable) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Speech recognition is not available on this device.')),
          );
          return;
        }
      }

      setState(() {
        _isListening = true;
        _transcribedText = "";
        _score = -1.0;
        _feedbackMessage = "Listening... Speak now!";
        _feedbackColor = AppColors.primary;
      });

      _pulseCtrl.repeat(reverse: true);

      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          setState(() {
            _transcribedText = result.recognizedWords;
          });
        },
        localeId: 'en_US',
        listenFor: const Duration(seconds: 5),
        pauseFor: const Duration(seconds: 2),
      );
    }
  }

  /// Evaluates how close the transcribed text is to the target word
  void _evaluatePronunciation() {
    final cleanTarget = widget.targetWord.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').trim();
    final cleanTranscribed = _transcribedText.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').trim();

    if (cleanTranscribed.isEmpty) {
      setState(() {
        _score = 0.0;
        _feedbackMessage = "We couldn't hear anything. Try again!";
        _feedbackColor = AppColors.error;
      });
      return;
    }

    // Levenshtein distance calculation
    final distance = _levenshtein(cleanTarget, cleanTranscribed);
    final maxLength = math.max(cleanTarget.length, cleanTranscribed.length);
    
    // Similarity ratio
    double ratio = 1.0 - (distance / maxLength);
    double scorePct = (ratio * 100).clamp(0.0, 100.0);

    // Provide higher score boost for minor variations to improve UX
    if (cleanTranscribed == cleanTarget) {
      scorePct = 100.0;
    } else if (cleanTarget.contains(cleanTranscribed) || cleanTranscribed.contains(cleanTarget)) {
      scorePct = math.max(scorePct, 85.0);
    }

    String message = "";
    Color color = AppColors.textSecondary;

    if (scorePct >= 85) {
      message = "Perfect pronunciation! 🎉";
      color = AppColors.success;
    } else if (scorePct >= 70) {
      message = "Good job! Almost there 👍";
      color = Colors.orange;
    } else {
      message = "Keep trying! Practice makes perfect 💪";
      color = AppColors.error;
    }

    setState(() {
      _score = scorePct;
      _feedbackMessage = message;
      _feedbackColor = color;
    });
  }

  /// Standard Levenshtein Distance Algorithm
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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.mic_none_rounded, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Pronunciation Practice',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
                  ),
                ],
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.volume_up_rounded, color: AppColors.primary, size: 22),
                onPressed: () => _tts.playWord(widget.targetWord, audioUrl: widget.audioUrl),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Main interactions area
          Row(
            children: [
              // Circular Mic Button
              GestureDetector(
                onTap: _toggleListening,
                child: AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (context, child) {
                    double value = _pulseCtrl.value;
                    return Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isListening
                            ? Colors.red.withOpacity(0.1 + (value * 0.15))
                            : AppColors.primary.withOpacity(0.1),
                      ),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isListening ? Colors.red : AppColors.primary,
                          boxShadow: _isListening
                              ? [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.4),
                                    blurRadius: 8 + (value * 8),
                                    spreadRadius: value * 4,
                                  )
                                ]
                              : null,
                        ),
                        child: Icon(
                          _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),

              // Transcription & Score info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_transcribedText.isEmpty && _score == -1.0)
                      const Text(
                        'Tap the mic and speak the word to test your pronunciation.',
                        style: TextStyle(fontSize: 12, color: AppColors.textHint, height: 1.4),
                      )
                    else ...[
                      // Transcribed text
                      if (_transcribedText.isNotEmpty)
                        RichText(
                          text: TextSpan(
                            children: [
                              const TextSpan(
                                text: 'You said: ',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                              ),
                              TextSpan(
                                text: '"$_transcribedText"',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontStyle: FontStyle.italic),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 4),

                      // Score badge & feedback
                      Row(
                        children: [
                          if (_score != -1.0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _feedbackColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: _feedbackColor.withOpacity(0.3)),
                              ),
                              child: Text(
                                '${_score.round()}% Match',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _feedbackColor),
                              ),
                            ),
                          if (_score != -1.0) const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _feedbackMessage,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _feedbackColor),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
