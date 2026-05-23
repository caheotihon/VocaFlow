import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/word_provider.dart';
import '../providers/learn_provider.dart';
import '../core/constants/app_constants.dart';
import 'widgets/shared_widgets.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});
  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> with TickerProviderStateMixin {
  late AnimationController _circleCtrl;
  late AnimationController _itemsCtrl;
  late Animation<double> _circleAnim;
  late Animation<double> _itemsFade;
  bool _showTranslation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WordProvider>().loadSources();
      context.read<WordProvider>().loadTopics();
    });

    _circleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _itemsCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _circleAnim = CurvedAnimation(parent: _circleCtrl, curve: Curves.easeOutQuart);
    _itemsFade = CurvedAnimation(parent: _itemsCtrl, curve: Curves.easeIn);

    _circleCtrl.forward().then((_) => _itemsCtrl.forward());
  }

  @override
  void dispose() {
    _circleCtrl.dispose();
    _itemsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isWide = size.width > 800;

    final result = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final accuracy      = result?['accuracy'] ?? 0;
    final xpEarned      = result?['xp_earned'] ?? 0;
    final correct       = result?['correct'] ?? 0;
    final wrong         = result?['wrong'] ?? 0;
    final total         = result?['total'] ?? 0;
    final streak        = result?['streak'] ?? 0;
    final milestone     = result?['milestoneReached'] as Map<String, dynamic>?;
    final dailyProgress = result?['dailyProgress'] as Map<String, dynamic>?;
    final dailyGoalMet   = dailyProgress?['dailyGoalMet'] == true;
    final isPerfect     = accuracy >= 90;

    // Show daily goal popup once after animations done
    if (dailyGoalMet) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 1800), () {
          if (mounted) _showDailyGoalDialog(context, dailyProgress!);
        });
      });
    }

    // Show milestone popup once after animations done
    if (milestone != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(Duration(milliseconds: dailyGoalMet ? 3600 : 1800), () {
          if (mounted) _showMilestoneDialog(context, milestone);
        });
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: isWide ? 40 : 24, vertical: 20),
              child: Column(
                children: [
                  _buildHeader(isPerfect, accuracy),
                  const SizedBox(height: 40),
                  isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildProgressCircle(accuracy, isPerfect)),
                          const SizedBox(width: 40),
                          Expanded(child: _buildStatsContent(correct, wrong, xpEarned, streak, total)),
                        ],
                      )
                    : Column(
                        children: [
                          _buildProgressCircle(accuracy, isPerfect),
                          const SizedBox(height: 32),
                          _buildStatsContent(correct, wrong, xpEarned, streak, total),
                        ],
                      ),
                  const SizedBox(height: 32),
                  _buildAiStoryCard(context),
                  const SizedBox(height: 40),
                  _buildActionButtons(context, isWide),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showMilestoneDialog(BuildContext context, Map<String, dynamic> milestone) {
    final days = milestone['days'] as int;
    final xp   = milestone['bonusXP'] as int;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(28),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Text('$days-Day Streak!',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900,
                    color: Colors.deepOrange)),
            const SizedBox(height: 8),
            Text('Amazing! You\'ve maintained your streak for $days days!',
                textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withOpacity(0.4)),
              ),
              child: Text('+$xp XP Bonus!',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                      color: Colors.amber)),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Awesome!', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDailyGoalDialog(BuildContext context, Map<String, dynamic> progress) {
    final learned = progress['dailyWordsLearned'] ?? 20;
    final goal    = progress['dailyGoal'] ?? 20;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(28),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⭐', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            const Text('Daily Goal Achieved!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900,
                    color: Colors.amber)),
            const SizedBox(height: 8),
            Text('Fantastic! You\'ve reached your daily goal by learning $learned / $goal words today!',
                textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.4)),
              ),
              child: const Text('+50 XP Goal Reward!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                      color: AppColors.primary)),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Awesome!', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI Components Tách biệt ---

  Widget _buildHeader(bool isPerfect, num accuracy) {
    return Column(
      children: [
        Text(
          isPerfect ? '🏆' : accuracy >= 60 ? '⭐' : '💪',
          style: const TextStyle(fontSize: 80),
        ),
        const SizedBox(height: 16),
        Text(
          isPerfect ? 'Perfect Score!' : accuracy >= 60 ? 'Great Job!' : 'Keep Practicing!',
          style: AppTextStyles.h1.copyWith(fontSize: 32),
          textAlign: TextAlign.center,
        ),
        const Text('Session Complete', style: AppTextStyles.bodySmall),
      ],
    );
  }

  Widget _buildProgressCircle(num accuracy, bool isPerfect) {
    return AnimatedBuilder(
      animation: _circleAnim,
      builder: (_, __) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.05), // Tạo hiệu ứng đổ bóng nhẹ
          ),
          child: SizedBox(
            width: 200, height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 200, height: 200,
                  child: CircularProgressIndicator(
                    value: (accuracy / 100) * _circleAnim.value,
                    strokeWidth: 16,
                    backgroundColor: Colors.grey.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isPerfect ? AppColors.success : AppColors.primary,
                    ),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(accuracy * _circleAnim.value).round()}%',
                      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900),
                    ),
                    const Text('ACCURACY', style: TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsContent(int correct, int wrong, int xp, int streak, int total) {
    return FadeTransition(
      opacity: _itemsFade,
      child: Column(
        children: [
          // Grid cho các chỉ số
          LayoutBuilder(builder: (context, constraints) {
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _StatBox(icon: Icons.check_circle_outline, value: '$correct', label: 'Correct', color: AppColors.success, width: (constraints.maxWidth / 2) - 12),
                _StatBox(icon: Icons.cancel_outlined, value: '$wrong', label: 'Wrong', color: AppColors.error, width: (constraints.maxWidth / 2) - 12),
                _StatBox(icon: Icons.bolt_rounded, value: '+$xp', label: 'XP Earned', color: Colors.amber, width: (constraints.maxWidth / 2) - 12),
                _StatBox(icon: Icons.menu_book_rounded, value: '$total', label: 'Words', color: Colors.blue, width: (constraints.maxWidth / 2) - 12),
              ],
            );
          }),
          const SizedBox(height: 20),
          // Streak Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 32)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Current Streak', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      Text('$streak days!', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isWide) {
    return FadeTransition(
      opacity: _itemsFade,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500), // Không để nút quá dài trên Desktop
        child: Column(
          children: [
            GradientButton(
              text: 'Practice Again',
              icon: Icons.replay_rounded,
              onTap: () => Navigator.pushNamedAndRemoveUntil(context, '/choose-mode', ModalRoute.withName('/home')),
            ),
            const SizedBox(height: 12),
            TextButton(
              style: TextButton.styleFrom(minimumSize: const Size(double.infinity, 54)),
              onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false),
              child: const Text('Back to Home', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiStoryCard(BuildContext context) {
    final lp = context.watch<LearnProvider>();
    final wordIds = lp.session?.words.map((w) => w.id).toList() ?? [];

    if (wordIds.isEmpty) return const SizedBox.shrink();

    return FadeTransition(
      opacity: _itemsFade,
      child: AppCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('✨', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI MEMORY STORY',
                        style: AppTextStyles.label.copyWith(color: AppColors.secondary, letterSpacing: 1.2),
                      ),
                      const Text(
                        'Connect Words in a Story',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (lp.isLoadingStory)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: AppColors.secondary),
                      const SizedBox(height: 12),
                      Text(
                        'Gemini AI is crafting a custom story for you...',
                        style: TextStyle(fontStyle: FontStyle.italic, color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
            else if (lp.aiStoryEn == null)
              Center(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary.withOpacity(0.1),
                    foregroundColor: AppColors.secondary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: AppColors.secondary),
                  ),
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: const Text('Generate Custom Story', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => lp.generateAiStory(wordIds),
                ),
              )
            else ...[
              // Story Container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.secondary.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _renderParsedHtmlText(lp.aiStoryEn!),
                    if (_showTranslation && lp.aiStoryVi != null) ...[
                      const Divider(height: 20),
                      Text(
                        lp.aiStoryVi!,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Translate toggle button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: AppColors.secondary),
                    icon: Icon(_showTranslation ? Icons.translate_rounded : Icons.g_translate_rounded),
                    label: Text(_showTranslation ? 'Hide Translation' : 'Translate to Vietnamese',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    onPressed: () {
                      setState(() {
                        _showTranslation = !_showTranslation;
                      });
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Helper to parse basic <b>text</b> tags into RichText widget
  Widget _renderParsedHtmlText(String text) {
    final List<TextSpan> spans = [];
    final regExp = RegExp(r'<b>(.*?)</b>');
    int start = 0;

    for (final match in regExp.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(
          text: text.substring(start, match.start),
          style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
        ));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: AppTextStyles.body.copyWith(
          color: AppColors.secondary,
          fontWeight: FontWeight.w900,
        ),
      ));
      start = match.end;
    }

    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color color;
  final double width;
  const _StatBox({required this.icon, required this.value, required this.label, required this.color, required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
          Text(label, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}