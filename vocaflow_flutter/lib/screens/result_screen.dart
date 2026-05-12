import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/word_provider.dart';
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
    // 1. Lấy kích thước màn hình để tính toán Responsive
    final size = MediaQuery.of(context).size;
    final bool isWide = size.width > 800; // Tablet/Desktop threshold

    final result = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final accuracy = result?['accuracy'] ?? 0;
    final xpEarned = result?['xp_earned'] ?? 0;
    final correct = result?['correct'] ?? 0;
    final wrong = result?['wrong'] ?? 0;
    final total = result?['total'] ?? 0;
    final streak = result?['streak'] ?? 0;
    final isPerfect = accuracy >= 90;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center( // Căn giữa nội dung cho Desktop
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000), // Giới hạn chiều rộng tối đa
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 40 : 24, 
                vertical: 20
              ),
              child: Column(
                children: [
                  _buildHeader(isPerfect, accuracy),
                  const SizedBox(height: 40),
                  
                  // Bố cục linh hoạt: Hàng ngang cho Desktop, Dọc cho Mobile
                  isWide 
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildProgressCircle(accuracy, isPerfect)),
                          const SizedBox(width: 40),
                          Expanded(flex: 1, child: _buildStatsContent(correct, wrong, xpEarned, streak, total)),
                        ],
                      )
                    : Column(
                        children: [
                          _buildProgressCircle(accuracy, isPerfect),
                          const SizedBox(height: 32),
                          _buildStatsContent(correct, wrong, xpEarned, streak, total),
                        ],
                      ),
                  
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