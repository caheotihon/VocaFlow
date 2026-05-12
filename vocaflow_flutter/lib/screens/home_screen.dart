// Home Dashboard Screen
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/stats_provider.dart';
import '../core/constants/app_constants.dart';
import 'widgets/shared_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StatsProvider>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth  = context.watch<AuthProvider>();
    final stats = context.watch<StatsProvider>();
    final user  = auth.user;
    final dash  = stats.dashboard;

    // Lấy kích thước màn hình để quyết định layout
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;
    final isTablet = width >= 600 && width < 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => context.read<StatsProvider>().loadDashboard(),
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            // Căn giữa và giới hạn độ rộng tối đa cho màn hình siêu lớn (Ultrawide/Desktop)
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 32 : 20, 
                    vertical: isDesktop ? 32 : 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Top bar (Giữ nguyên cho mọi màn hình) ───────────────
                      _buildTopBar(user),
                      const SizedBox(height: 24),

                      // ── Nội dung chính (Thay đổi theo màn hình) ─────────────
                      if (isDesktop) 
                        // Layout 2 cột cho Desktop
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 7,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildResumeCard(context),
                                  const SizedBox(height: 32),
                                  _buildQuickActions(context, crossAxisCount: 4, aspectRatio: 1.8),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 4,
                              child: Column(
                                children: [
                                  _buildDailyProgress(user, dash),
                                  const SizedBox(height: 16),
                                  _buildDailyStats(user),
                                ],
                              ),
                            ),
                          ],
                        )
                      else 
                        // Layout 1 cột dọc cho Mobile & Tablet
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildResumeCard(context),
                            const SizedBox(height: 16),
                            _buildDailyStats(user),
                            const SizedBox(height: 16),
                            _buildDailyProgress(user, dash),
                            const SizedBox(height: 24),
                            _buildQuickActions(
                              context, 
                              crossAxisCount: isTablet ? 4 : 2, 
                              aspectRatio: isTablet ? 1.2 : 1.5,
                            ),
                          ],
                        ),
                      
                      const SizedBox(height: 80), // khoảng trống cho bottom nav trên mobile
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── CÁC WIDGET THÀNH PHẦN ĐƯỢC TÁCH RA ĐỂ TÁI SỬ DỤNG ───────────────────────

  Widget _buildTopBar(user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primary.withOpacity(0.15),
              child: user?.avatar != null
                  ? ClipOval(child: Image.network(user!.avatar!, fit: BoxFit.cover))
                  : Text(
                      user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 18),
                    ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hello,', style: AppTextStyles.bodySmall),
                Text(
                  '${user?.name ?? 'Learner'}!',
                  style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
                ),
              ],
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 4),
              Text(
                '${user?.streakDays ?? 0}d',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.deepOrange, fontSize: 15),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResumeCard(BuildContext context) {
    return AppCard(
      hasBorder: true,
      padding: const EdgeInsets.all(20),
      onTap: () => Navigator.pushNamed(context, '/learn'),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('RESUME', style: AppTextStyles.label.copyWith(
                  color: AppColors.primary, letterSpacing: 1.2)),
                const SizedBox(height: 6),
                const Text('Oxford 5000',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('Tap to continue learning',
                    style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(
                color: AppColors.primary.withOpacity(0.35),
                blurRadius: 12, offset: const Offset(0, 4),
              )],
            ),
            child: const Icon(Icons.play_arrow_rounded,
                color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyStats(user) {
    return Row(
      children: [
        Expanded(
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.bolt, color: AppColors.primary, size: 20),
                ),
                const SizedBox(height: 10),
                const Text('Daily XP', style: AppTextStyles.bodySmall),
                const SizedBox(height: 2),
                Text(
                  '${user?.dailyXP ?? 0}',
                  style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.track_changes,
                      color: AppColors.secondary, size: 20),
                ),
                const SizedBox(height: 10),
                const Text('Goal Accuracy', style: AppTextStyles.bodySmall),
                const SizedBox(height: 2),
                Text(
                  '${user?.goalAccuracy ?? 80}%',
                  style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDailyProgress(user, dash) {
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Daily Progress', style: AppTextStyles.bodySmall),
                const SizedBox(height: 4),
                const Text('Words learned',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 6),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${dash?['progress']?['totalLearned'] ?? 0}',
                        style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800,
                          color: AppColors.primary),
                      ),
                      TextSpan(
                        text: ' / ${user?.dailyGoal ?? 20}',
                        style: AppTextStyles.body.copyWith(
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 70, height: 70,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: ((dash?['progress']?['totalLearned'] ?? 0) /
                          (user?.dailyGoal ?? 20)).clamp(0.0, 1.0),
                  strokeWidth: 6,
                  backgroundColor: AppColors.background,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
                const Icon(Icons.star_rounded,
                    color: AppColors.primary, size: 26),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, {required int crossAxisCount, required double aspectRatio}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Quick Actions'),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: aspectRatio,
          children: [
            _QuickActionCard(
              icon: Icons.menu_book_rounded,
              label: 'Learn Vocab',
              color: AppColors.primary,
              onTap: () => Navigator.pushNamed(context, '/learn'),
            ),
            _QuickActionCard(
              icon: Icons.quiz_outlined,
              label: 'Take a Quiz',
              color: AppColors.secondary,
              onTap: () => Navigator.pushNamed(context, '/learn'),
            ),
            _QuickActionCard(
              icon: Icons.history_rounded,
              label: 'Review Mistakes',
              color: Colors.redAccent,
              onTap: () => Navigator.pushNamed(context, '/favorites'),
            ),
            _QuickActionCard(
              icon: Icons.favorite_border_rounded,
              label: 'Favorites',
              color: Colors.pinkAccent,
              onTap: () => Navigator.pushNamed(context, '/favorites'),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon, required this.label,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click, // Thêm con trỏ tay chỉ cho Web/Desktop
      child: GestureDetector(
        onTap: onTap,
        child: Container(
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(label,
                  style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}