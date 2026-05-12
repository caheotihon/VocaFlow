// Profile Screen
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/stats_provider.dart';
import '../core/constants/app_constants.dart';
import 'widgets/shared_widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth  = context.watch<AuthProvider>();
    final stats = context.watch<StatsProvider>();
    final user  = auth.user;
    final dash  = stats.dashboard;
    final progress = dash?['progress'] as Map<String, dynamic>? ?? {};

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          // ── Responsive Layout: Căn giữa và giới hạn chiều rộng ────────
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800), // Profile ưu tiên hẹp hơn Grid
              child: Column(
                children: [
                  // ── Avatar + name ───────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      boxShadow: [
                        BoxShadow(color: AppColors.primary.withOpacity(0.25),
                            blurRadius: 20, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 44,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              child: user?.avatar != null
                                  ? ClipOval(child: Image.network(user!.avatar!, fit: BoxFit.cover,
                                      width: 88, height: 88))
                                  : Text(
                                      user?.name.isNotEmpty == true
                                          ? user!.name[0].toUpperCase() : 'U',
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800),
                                    ),
                            ),
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () {
                                  // TODO: Handle edit avatar
                                },
                                child: Container(
                                  width: 28, height: 28,
                                  decoration: BoxDecoration(
                                    color: Colors.white, shape: BoxShape.circle,
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                                  ),
                                  child: const Icon(Icons.edit_rounded, color: AppColors.primary, size: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(user?.name ?? 'Learner',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(user?.email ?? '',
                            style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 14)),
                        const SizedBox(height: 16),

                        // Streak + XP row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _StatPill('🔥 ${user?.streakDays ?? 0}d', 'Streak'),
                            Container(width: 1, height: 32, color: Colors.white.withOpacity(0.3)),
                            _StatPill('⚡ ${user?.totalXP ?? 0}', 'Total XP'),
                            Container(width: 1, height: 32, color: Colors.white.withOpacity(0.3)),
                            _StatPill('📚 ${progress['totalMastered'] ?? 0}', 'Mastered'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Goals section ───────────────────────────────────────
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Learning Goals', style: AppTextStyles.h3),
                        const SizedBox(height: 16),
                        _GoalRow(
                          icon: Icons.today_rounded,
                          label: 'Daily Goal',
                          value: '${user?.dailyGoal ?? 20} words/day',
                          color: AppColors.primary,
                        ),
                        const Divider(height: 20),
                        _GoalRow(
                          icon: Icons.track_changes_rounded,
                          label: 'Target Accuracy',
                          value: '${user?.goalAccuracy ?? 80}%',
                          color: AppColors.secondary,
                        ),
                        const Divider(height: 20),
                        _GoalRow(
                          icon: Icons.local_fire_department_rounded,
                          label: 'Current Streak',
                          value: '${user?.streakDays ?? 0} days',
                          color: Colors.deepOrange,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Badges ──────────────────────────────────────────────
                  if ((user?.badges ?? []).isNotEmpty)
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Badges Earned', style: AppTextStyles.h3),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 10, runSpacing: 10,
                            children: (user!.badges).map((b) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(AppRadius.full),
                                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                              ),
                              child: Text('🏆 $b',
                                  style: const TextStyle(
                                      color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                            )).toList(),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  // ── Settings / Logout ───────────────────────────────────
                  AppCard(
                    child: Column(
                      children: [
                        _SettingsTile(
                          icon: Icons.notifications_outlined,
                          label: 'Notifications',
                          onTap: () {},
                        ),
                        const Divider(height: 1),
                        _SettingsTile(
                          icon: Icons.help_outline_rounded,
                          label: 'Help & Support',
                          onTap: () {},
                        ),
                        const Divider(height: 1),
                        _SettingsTile(
                          icon: Icons.privacy_tip_outlined,
                          label: 'Privacy Policy',
                          onTap: () {},
                        ),
                        const Divider(height: 1),
                        _SettingsTile(
                          icon: Icons.logout_rounded,
                          label: 'Sign Out',
                          color: AppColors.error,
                          onTap: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.lg)),
                                title: const Text('Sign Out?',
                                    style: TextStyle(fontWeight: FontWeight.w700)),
                                content: const Text('Are you sure you want to sign out?'),
                                actions: [
                                  TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Cancel')),
                                  TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text('Sign Out',
                                          style: TextStyle(color: AppColors.error))),
                                ],
                              ),
                            );
                            if (confirm == true && context.mounted) {
                              await context.read<AuthProvider>().logout();
                              Navigator.pushReplacementNamed(context, '/login');
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String value, label;
  const _StatPill(this.value, this.label);
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: const TextStyle(
          color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
    ],
  );
}

class _GoalRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _GoalRow({required this.icon, required this.label,
      required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      const SizedBox(width: 12),
      Expanded(child: Text(label, style: AppTextStyles.body)),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
    ],
  );
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _SettingsTile({required this.icon, required this.label,
      required this.onTap, this.color});
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: color ?? AppColors.textSecondary, size: 22),
    title: Text(label, style: TextStyle(
        fontWeight: FontWeight.w500,
        color: color ?? AppColors.textPrimary)),
    trailing: Icon(Icons.chevron_right_rounded,
        color: Colors.grey.shade400, size: 20),
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(vertical: 2),
  );
}