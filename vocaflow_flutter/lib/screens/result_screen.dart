import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/word_provider.dart';
import 'dart:math' as math;
import '../core/constants/app_constants.dart';
import 'widgets/shared_widgets.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});
  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _circleCtrl;
  late AnimationController _itemsCtrl;
  late Animation<double> _circleAnim;
  late Animation<double> _itemsFade;

  @override
  void initState() {
    super.initState();

    // Refresh progress data in background
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WordProvider>().loadSources();
      context.read<WordProvider>().loadTopics();
    });

    _circleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _itemsCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _circleAnim = CurvedAnimation(parent: _circleCtrl, curve: Curves.easeOut);
    _itemsFade  = CurvedAnimation(parent: _itemsCtrl,  curve: Curves.easeIn);

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
    final result = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final accuracy    = result?['accuracy']  ?? 0;
    final xpEarned    = result?['xp_earned'] ?? 0;
    final correct     = result?['correct']   ?? 0;
    final wrong       = result?['wrong']     ?? 0;
    final total       = result?['total']     ?? 0;
    final streak      = result?['streak']    ?? 0;
    final isPerfect   = accuracy >= 90;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // ── Trophy / emoji ──────────────────────────────────────
              Text(
                isPerfect ? '🏆' : accuracy >= 60 ? '⭐' : '💪',
                style: const TextStyle(fontSize: 64),
              ),
              const SizedBox(height: 12),
              Text(
                isPerfect ? 'Perfect Score!' : accuracy >= 60 ? 'Great Job!' : 'Keep Practicing!',
                style: AppTextStyles.h1,
              ),
              const SizedBox(height: 4),
              const Text('Session Complete', style: AppTextStyles.bodySmall),
              const SizedBox(height: 36),

              // ── Accuracy ring ───────────────────────────────────────
              AnimatedBuilder(
                animation: _circleAnim,
                builder: (_, __) => SizedBox(
                  width: 160, height: 160,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 160, height: 160,
                        child: CircularProgressIndicator(
                          value: (accuracy / 100) * _circleAnim.value,
                          strokeWidth: 12,
                          backgroundColor: AppColors.background,
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
                            style: const TextStyle(
                              fontSize: 36, fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary),
                          ),
                          const Text('Accuracy', style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── Stats row ───────────────────────────────────────────
              FadeTransition(
                opacity: _itemsFade,
                child: Row(
                  children: [
                    _StatBox(
                      icon: Icons.check_circle_outline_rounded,
                      value: correct.toString(),
                      label: 'Correct',
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 12),
                    _StatBox(
                      icon: Icons.cancel_outlined,
                      value: wrong.toString(),
                      label: 'Wrong',
                      color: AppColors.error,
                    ),
                    const SizedBox(width: 12),
                    _StatBox(
                      icon: Icons.bolt_rounded,
                      value: '+$xpEarned',
                      label: 'XP Earned',
                      color: Colors.amber,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── XP & streak banner ──────────────────────────────────
              FadeTransition(
                opacity: _itemsFade,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Row(
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Current Streak',
                                style: TextStyle(color: Colors.white70, fontSize: 13)),
                            Text('$streak days!',
                                style: const TextStyle(
                                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                      Text('$total words\nstudied',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                          textAlign: TextAlign.right),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── Action buttons ──────────────────────────────────────
              FadeTransition(
                opacity: _itemsFade,
                child: Column(
                  children: [
                    GradientButton(
                      text: 'Practice Again',
                      icon: Icons.replay_rounded,
                      onTap: () => Navigator.pushNamedAndRemoveUntil(
                          context, '/choose-mode', ModalRoute.withName('/home')),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.full)),
                        side: const BorderSide(color: AppColors.primary),
                      ),
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                          context, '/home', (r) => false),
                      child: const Text('Go Home',
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color color;
  const _StatBox({required this.icon, required this.value,
      required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }
}
