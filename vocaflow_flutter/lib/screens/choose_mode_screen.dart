import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/learn_provider.dart';
import '../core/constants/app_constants.dart';
import 'widgets/shared_widgets.dart';

class ChooseModeScreen extends StatelessWidget {
  const ChooseModeScreen({super.key});

  static const _modes = [
    {
      'id':    'flashcard',
      'label': 'Flashcards',
      'icon':  Icons.style_rounded,
      'desc':  'Flip cards to learn word meanings',
      'color': Color(0xFF4F46E5),
    },
    {
      'id':    'typing',
      'label': 'Typing Challenge',
      'icon':  Icons.keyboard_alt_outlined,
      'desc':  'Type the word from the definition',
      'color': Color(0xFF7C3AED),
    },
    {
      'id':    'listening',
      'label': 'Listening Recall',
      'icon':  Icons.headphones_rounded,
      'desc':  'Hear the word and identify it',
      'color': Color(0xFF0EA5E9),
    },
    {
      'id':    'reverse_recall',
      'label': 'Reverse Recall',
      'icon':  Icons.swap_horiz_rounded,
      'desc':  'See definition, recall the word',
      'color': Color(0xFF10B981),
    },
    {
      'id':    'fill_blank',
      'label': 'Fill in the Blank',
      'icon':  Icons.edit_note_rounded,
      'desc':  'Complete the sentence with the word',
      'color': Color(0xFFF59E0B),
    },
    {
      'id':    'mixed',
      'label': 'Mixed Challenge',
      'icon':  Icons.shuffle_rounded,
      'desc':  'All modes combined for deep learning',
      'color': Color(0xFFEF4444),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final learnP = context.watch<LearnProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
        centerTitle: true,
        title: const Text('LingoPro',
            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        // Giới hạn chiều rộng tối đa cho Tablet/Desktop
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1024),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Column(
                      crossAxisAlignment: isDesktop ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                      children: [
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
                                '${learnP.selectedSource} • ${learnP.selectedLevel ?? 'All'}'
                                '${learnP.selectedTopic != null ? ' • ${learnP.selectedTopic}' : ''}',
                                style: const TextStyle(
                                  color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text('Choose Practice Mode', style: AppTextStyles.h1, textAlign: TextAlign.center),
                        const SizedBox(height: 4),
                        const Text('Select how you want to practice today.',
                            style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
                        const SizedBox(height: 24),

                        // Responsive Grid sử dụng Wrap + LayoutBuilder
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            // Tính toán số cột dựa trên chiều rộng hiện tại
                            int columns = width >= 800 ? 3 : (width >= 550 ? 2 : 1);
                            double spacing = 16.0;
                            // Tính toán chiều rộng của từng item
                            double itemWidth = (width - (spacing * (columns - 1))) / columns;

                            return Wrap(
                              spacing: spacing,
                              runSpacing: spacing,
                              children: _modes.map((mode) {
                                final isSelected = learnP.selectedMode == mode['id'];
                                return SizedBox(
                                  width: columns == 1 ? double.infinity : itemWidth,
                                  child: _ModeCard(
                                    id:         mode['id'] as String,
                                    label:      mode['label'] as String,
                                    icon:       mode['icon'] as IconData,
                                    desc:       mode['desc'] as String,
                                    color:      mode['color'] as Color,
                                    isSelected: isSelected,
                                    onTap: () => context.read<LearnProvider>().selectMode(mode['id'] as String),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // Start button - Căn giữa và giới hạn độ rộng trên Desktop
                Align(
                  alignment: Alignment.bottomCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      child: GradientButton(
                        text: 'Start Session',
                        icon: Icons.play_arrow_rounded,
                        isLoading: learnP.isLoading,
                        onTap: learnP.selectedMode != null
                            ? () async {
                                final ok = await learnP.startSession();
                                if (!context.mounted) return;
                                if (ok) {
                                  final route = _getRoute(learnP.selectedMode!);
                                  Navigator.pushNamed(context, route);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(learnP.error ?? 'Failed to start session'),
                                      backgroundColor: AppColors.error,
                                      behavior: SnackBarBehavior.floating, // Floating đẹp hơn trên desktop
                                    ),
                                  );
                                }
                              }
                            : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getRoute(String mode) {
    switch (mode) {
      case 'typing':        return '/practice/typing';
      case 'listening':     return '/practice/listening';
      case 'reverse_recall':return '/practice/reverse';
      case 'fill_blank':    return '/practice/fill-blank';
      case 'mixed':         return '/practice/mixed';
      default:              return '/practice/flashcard';
    }
  }
}

// Giữ nguyên _ModeCard như cũ vì thiết kế thẻ của bạn đã hoàn toàn responsive nội bộ
class _ModeCard extends StatelessWidget {
  final String id, label, desc;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeCard({
    required this.id, required this.label, required this.icon,
    required this.desc, required this.color,
    required this.isSelected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.07) : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade100,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? color.withOpacity(0.15) : Colors.black.withOpacity(0.04),
              blurRadius: 10, offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: isSelected ? color : AppColors.textPrimary,
                      )),
                  const SizedBox(height: 3),
                  Text(desc, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: color, size: 24),
          ],
        ),
      ),
    );
  }
}