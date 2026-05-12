// Select Topic Screen — Step 2: Choose a topic to study
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/learn_provider.dart';
import '../providers/word_provider.dart';
import '../core/constants/app_constants.dart';
import 'widgets/shared_widgets.dart';

class SelectTopicScreen extends StatefulWidget {
  const SelectTopicScreen({super.key});
  @override
  State<SelectTopicScreen> createState() => _SelectTopicScreenState();
}

class _SelectTopicScreenState extends State<SelectTopicScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lp = context.read<LearnProvider>();
      context.read<WordProvider>().loadTopics(
        source: lp.selectedSource,
        level:  lp.selectedLevel,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final wordP  = context.watch<WordProvider>();
    final learnP = context.watch<LearnProvider>();
    final topics = wordP.topics;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
        title: const Text('LingoPro',
            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                // ── Responsive Layout: Căn giữa và giới hạn chiều rộng ────────
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Breadcrumb chip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.school_outlined, color: AppColors.primary, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                '${learnP.selectedSource} • ${learnP.selectedLevel ?? 'All'}',
                                style: const TextStyle(
                                    color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text('Select Topic', style: AppTextStyles.h1),
                        const SizedBox(height: 4),
                        const Text('Choose a category to focus your practice session.',
                            style: AppTextStyles.bodySmall),
                        const SizedBox(height: 24),

                        if (wordP.isLoading)
                          const Center(child: CircularProgressIndicator(color: AppColors.primary))
                        else if (topics.isEmpty)
                          Center(
                            child: Column(
                              children: [
                                const SizedBox(height: 40),
                                Icon(Icons.folder_open, size: 60, color: Colors.grey.shade300),
                                const SizedBox(height: 12),
                                const Text('No topics found for this selection.',
                                    style: AppTextStyles.bodySmall),
                              ],
                            ),
                          )
                        else
                          ...topics.asMap().entries.map((e) {
                            final i     = e.key;
                            final topic = e.value;
                            final name     = topic['topic'] as String? ?? '';
                            final total    = topic['total'] as int? ?? 0;
                            final mastered = topic['mastered'] as int? ?? 0;
                            final learning = topic['learning'] as int? ?? 0;
                            final newCount = topic['new'] as int? ?? total;
                            final hasProgress = mastered > 0 || learning > 0;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _TopicCard(
                                index:    i + 1,
                                topic:    name,
                                total:    total,
                                mastered: mastered,
                                learning: learning,
                                newCount: newCount,
                                hasProgress: hasProgress,
                                onStart: () {
                                  learnP.selectTopic(name);
                                  Navigator.pushNamed(context, '/choose-mode');
                                },
                              ),
                            );
                          }),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  final int index, total, mastered, learning, newCount;
  final String topic;
  final bool hasProgress;
  final VoidCallback onStart;

  const _TopicCard({
    required this.index, required this.topic, required this.total,
    required this.mastered, required this.learning, required this.newCount,
    required this.hasProgress, required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    index.toString().padLeft(2, '0'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(topic,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    Text('$total WORDS',
                        style: AppTextStyles.label),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatDot(label: '$mastered mastered', color: AppColors.mastered),
              const SizedBox(width: 12),
              _StatDot(label: '$learning learning', color: AppColors.learning),
              const SizedBox(width: 12),
              _StatDot(label: '$newCount new', color: AppColors.newWord),
            ],
          ),
          const SizedBox(height: 10),
          AppProgressBar(
            value: total > 0 ? (mastered + learning) / total : 0,
            height: 5,
          ),
          const SizedBox(height: 12),
          // ── Tối ưu UI cho nút bấm trên Web ────────
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onStart,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: hasProgress ? AppColors.primaryGradient : null,
                  color: hasProgress ? null : AppColors.background,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.play_arrow_rounded,
                      color: hasProgress ? Colors.white : AppColors.textSecondary,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Start Practice',
                      style: TextStyle(
                        color: hasProgress ? Colors.white : AppColors.textSecondary,
                        fontWeight: FontWeight.w600, fontSize: 14,
                      ),
                    ),
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

class _StatDot extends StatelessWidget {
  final String label;
  final Color color;
  const _StatDot({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}