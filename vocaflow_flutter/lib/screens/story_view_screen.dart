import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../providers/story_provider.dart';
import '../models/word_model.dart';
import '../core/constants/app_constants.dart';
import 'widgets/shared_widgets.dart';

class StoryViewScreen extends StatefulWidget {
  const StoryViewScreen({super.key});

  @override
  State<StoryViewScreen> createState() => _StoryViewScreenState();
}

class _StoryViewScreenState extends State<StoryViewScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _showTranslation = false;

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
                // Header with Word and Part of Speech
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

                // Meaning & Definition
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

                // Example Sentence
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

  @override
  Widget build(BuildContext context) {
    final storyP = context.watch<StoryProvider>();
    final story = storyP.currentStory;

    if (story == null) {
      return Scaffold(
        appBar: const LingoAppBar(title: 'Read Story', showStreak: false),
        body: const Center(child: Text('No story loaded')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7), // Warm premium paper background
      appBar: LingoAppBar(
        title: 'Read AI Story',
        showStreak: false,
        backgroundColor: const Color(0xFFFDFBF7),
        actions: [
          if (story.translation.isNotEmpty)
            IconButton(
              icon: Icon(
                _showTranslation ? Icons.g_translate_rounded : Icons.translate_rounded,
                color: _showTranslation ? AppColors.primary : AppColors.textSecondary,
              ),
              tooltip: 'Dịch truyện',
              onPressed: () {
                setState(() {
                  _showTranslation = !_showTranslation;
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: AppColors.textSecondary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tap highlighted words in the story to view definitions & hear pronunciation! 🎙️'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Book Title
                  Text(
                    story.title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      fontFamily: 'Georgia',
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Author / Subtext
                  Row(
                    children: [
                      const Icon(Icons.psychology_rounded, size: 16, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Written by LingoPro AI',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${story.words.length} vocab words',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: Colors.black12),
                  const SizedBox(height: 20),

                  // Story Body
                  RichText(
                    text: TextSpan(
                      children: _buildStorySpans(story.content, story.words, context),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Optional Premium Translation Card
                  if (_showTranslation && story.translation.isNotEmpty) ...[
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.g_translate_rounded, size: 20, color: AppColors.primary),
                              const SizedBox(width: 8),
                              const Text(
                                'Bản dịch tiếng Việt',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1, color: Colors.black12),
                          const SizedBox(height: 12),
                          Text(
                            story.translation,
                            style: const TextStyle(
                              fontSize: 16,
                              fontFamily: 'Georgia',
                              height: 1.7,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Bottom Bar containing action button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                )
              ],
            ),
            child: SafeArea(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/story/quiz');
                },
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
                      story.isCompleted ? 'Review Comprehension Quiz' : 'Start Comprehension Quiz',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.quiz_rounded, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HoverWordPopup extends StatefulWidget {
  final WordModel word;
  final String matchedText;
  final VoidCallback onTap;

  const HoverWordPopup({
    super.key,
    required this.word,
    required this.matchedText,
    required this.onTap,
  });

  @override
  State<HoverWordPopup> createState() => _HoverWordPopupState();
}

class _HoverWordPopupState extends State<HoverWordPopup> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  bool _isHovered = false;

  void _showOverlay() {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          width: 300,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, -8),
            targetAnchor: Alignment.topCenter,
            followerAnchor: Alignment.bottomCenter,
            child: MouseRegion(
              onEnter: (_) => _isHovered = true,
              onExit: (_) {
                _isHovered = false;
                _hideOverlay();
              },
              child: Material(
                elevation: 12,
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                shadowColor: Colors.black26,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withOpacity(0.12)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              widget.word.word,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              widget.word.partOfSpeech.toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (widget.word.pronunciation.isNotEmpty) ...[
                        Text(
                          '/${widget.word.pronunciation}/',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      const Divider(height: 1, color: Colors.black12),
                      const SizedBox(height: 10),
                      Text(
                        'Nghĩa:',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.word.meaningVn,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      if (widget.word.definitionEn.isNotEmpty || widget.word.definitionVn.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Định nghĩa:',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.word.definitionEn.isNotEmpty ? widget.word.definitionEn : widget.word.definitionVn,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      if (!_isHovered) {
        _overlayEntry?.remove();
        _overlayEntry = null;
      }
    });
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) {
          setState(() {
            _isHovered = true;
          });
          _showOverlay();
        },
        onExit: (_) {
          setState(() {
            _isHovered = false;
          });
          _hideOverlay();
        },
        child: GestureDetector(
          onTap: widget.onTap,
          child: Text(
            widget.matchedText,
            style: const TextStyle(
              fontSize: 17,
              fontFamily: 'Georgia',
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.primary,
              decorationThickness: 1.8,
            ),
          ),
        ),
      ),
    );
  }
}
