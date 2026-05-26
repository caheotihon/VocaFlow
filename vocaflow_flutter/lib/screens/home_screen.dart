// Home Dashboard Screen
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/stats_provider.dart';
import '../providers/learn_provider.dart';
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
                                  _buildResumeCard(context, dash),
                                  const SizedBox(height: 16),
                                  _buildAiStoryCard(context),
                                  const SizedBox(height: 24),
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
                                  _buildDailyStats(user, dash),
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
                            _buildResumeCard(context, dash),
                            const SizedBox(height: 16),
                            _buildDailyStats(user, dash),
                            const SizedBox(height: 16),
                            _buildDailyProgress(user, dash),
                            const SizedBox(height: 16),
                            _buildAiStoryCard(context),
                            const SizedBox(height: 16),
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
                  ? ClipOval(
                      child: user!.avatar!.startsWith('data:image/')
                          ? Image.memory(
                              base64.decode(user!.avatar!.split(',').last),
                              fit: BoxFit.cover,
                              width: 44,
                              height: 44,
                              errorBuilder: (_, __, ___) => Text(
                                user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 18),
                              ),
                            )
                          : Image.network(
                              user!.avatar!,
                              fit: BoxFit.cover,
                              width: 44,
                              height: 44,
                              errorBuilder: (_, __, ___) => Text(
                                user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 18),
                              ),
                            ),
                    )
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

  Widget _buildResumeCard(BuildContext context, dash) {
    final resume = dash?['resume'] as Map<String, dynamic>?;
    final activeSession = resume?['activeSession'] as Map<String, dynamic>?;
    final nextRec = resume?['nextRecommendation'] as Map<String, dynamic>?;

    if (activeSession == null && nextRec == null) {
      return const SizedBox.shrink();
    }

    final bool isActive = activeSession != null;
    final Map<String, dynamic> data = isActive ? activeSession : nextRec!;

    final String source = data['source'] ?? 'General';
    final String? level = data['level'];
    final String? topic = data['topic'];
    final String mode = data['mode'] ?? 'mixed';

    String title = source;
    if (level != null) title += ' • $level';
    if (topic != null) title += ' ($topic)';

    return AppCard(
      hasBorder: true,
      padding: const EdgeInsets.all(20),
      onTap: () async {
        final learnP = context.read<LearnProvider>();
        if (isActive) {
          final bool success = await learnP.resumeSession();
          if (success && mounted) {
            final route = _getRoute(mode);
            Navigator.pushNamed(context, route);
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to resume session. Please try again! 🚀')),
            );
          }
        } else {
          learnP.selectedSource = source;
          learnP.selectedLevel = level;
          learnP.selectedTopic = topic;
          learnP.selectedMode = mode;
          final bool success = await learnP.startSession();
          if (success && mounted) {
            final route = _getRoute(mode);
            Navigator.pushNamed(context, route);
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to start next session. Please try again! 🚀')),
            );
          }
        }
      },
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isActive ? 'RESUME LEARNING' : 'RECOMMENDED FOR YOU',
                  style: AppTextStyles.label.copyWith(
                    color: isActive ? AppColors.primary : Colors.amber.shade800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  isActive 
                      ? 'Tap to continue (${activeSession['currentIndex']} / ${activeSession['total_words']} words)' 
                      : 'Tap to start next topic',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              gradient: isActive ? AppColors.primaryGradient : null,
              color: isActive ? null : Colors.amber.shade600,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isActive ? AppColors.primary : Colors.amber).withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  String _getRoute(String mode) {
    switch (mode) {
      case 'typing':        return '/practice/typing';
      case 'listening':     return '/practice/listening';
      case 'reverse_recall':return '/practice/reverse';
      case 'fill_blank':    return '/practice/fill-blank';
      case 'speech':        return '/practice/speech';
      case 'mixed':         return '/practice/mixed';
      default:              return '/practice/flashcard';
    }
  }

  Widget _buildDailyStats(user, dash) {
    final dailyXP = dash?['user']?['dailyXP'] ?? user?.dailyXP ?? 0;
    final accuracy = dash?['progress']?['accuracy'] ?? 80;

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
                  '$dailyXP',
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
                  '$accuracy%',
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
    final dailyWords = dash?['progress']?['dailyWordsLearned'] ?? 0;
    final goal = user?.dailyGoal ?? 20;
    final isGoalMet = dailyWords >= goal;

    return AppCard(
      onTap: () {
        if (isGoalMet) {
          _showDailyRewardDialog(context, dailyWords, goal);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Learn ${goal - dailyWords} more words to achieve your daily goal! 🚀'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
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
                        text: '$dailyWords',
                        style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800,
                          color: isGoalMet ? Colors.amber.shade700 : AppColors.primary),
                      ),
                      TextSpan(
                        text: ' / $goal',
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
                  value: (dailyWords / goal).clamp(0.0, 1.0),
                  strokeWidth: 6,
                  backgroundColor: AppColors.background,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isGoalMet ? Colors.amber : AppColors.primary
                  ),
                ),
                Icon(
                  isGoalMet ? Icons.stars_rounded : Icons.star_rounded,
                  color: isGoalMet ? Colors.amber : AppColors.primary,
                  size: isGoalMet ? 32 : 26,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDailyRewardDialog(BuildContext context, int dailyWords, int goal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.emoji_events_rounded,
                color: Colors.amber.shade800,
                size: 64,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Daily Goal Met! 🎉',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Congratulations! You learned $dailyWords / $goal words today and achieved your daily goal!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('⚡', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    '+50 XP Daily Reward',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                elevation: 2,
              ),
              child: const Text(
                'Awesome!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
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
              icon: Icons.leaderboard_rounded,
              label: 'Leaderboard',
              color: AppColors.secondary,
              onTap: () => Navigator.pushNamed(context, '/leaderboard'),
            ),
            _QuickActionCard(
              icon: Icons.replay_circle_filled_rounded,
              label: 'Review Today',
              color: Colors.redAccent,
              onTap: () => Navigator.pushNamed(context, '/review/history'),
            ),
            _QuickActionCard(
              icon: Icons.history_rounded,
              label: 'Quiz History',
              color: Colors.blue,
              onTap: () => Navigator.pushNamed(context, '/practice-history'),
            ),
            _QuickActionCard(
              icon: Icons.history_edu_rounded,
              label: 'Story History',
              color: const Color(0xFF6366F1),
              onTap: () => Navigator.pushNamed(context, '/story/history'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAiStoryCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, '/story/select-words'),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('✨', style: TextStyle(fontSize: 12, color: Colors.white)),
                            SizedBox(width: 4),
                            Text(
                              'AI POWERED',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Smart Story Generator',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Weave your vocab list into an elegant English story!',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_stories_rounded,
                    color: Color(0xFF6366F1),
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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