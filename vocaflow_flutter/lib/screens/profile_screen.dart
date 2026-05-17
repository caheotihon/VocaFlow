// Profile Screen — full profile management with edit, streak milestones, badges
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
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
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                children: [
                  // ── Avatar + name hero card ─────────────────────────
                  _ProfileHeroCard(user: user, progress: progress),
                  const SizedBox(height: 20),

                  // ── Streak Milestone Progress ───────────────────────
                  _StreakMilestonesCard(user: user),
                  const SizedBox(height: 16),

                  // ── Goals section ───────────────────────────────────
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Learning Goals', style: AppTextStyles.h3),
                            TextButton.icon(
                              onPressed: () => _showEditGoalsDialog(context, user),
                              icon: const Icon(Icons.edit_outlined, size: 16),
                              label: const Text('Edit'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                textStyle: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
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
                          label: 'Best Streak',
                          value: '${user?.bestStreak ?? 0} days',
                          color: Colors.deepOrange,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Badges ──────────────────────────────────────────
                  if ((user?.badges ?? []).isNotEmpty)
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Badges Earned', style: AppTextStyles.h3),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 10, runSpacing: 10,
                            children: (user!.badges).map((b) => _BadgeChip(badge: b)).toList(),
                          ),
                        ],
                      ),
                    ),
                  if ((user?.badges ?? []).isNotEmpty) const SizedBox(height: 16),

                  // ── Settings / Logout ───────────────────────────────
                  AppCard(
                    child: Column(
                      children: [
                        _SettingsTile(
                          icon: Icons.person_outline_rounded,
                          label: 'Edit Profile',
                          onTap: () => _showEditProfileDialog(context, user),
                        ),
                        const Divider(height: 1),
                        _SettingsTile(
                          icon: Icons.notifications_active_outlined,
                          label: 'Study Reminders',
                          trailing: Switch(
                            value: true, // Dummy value
                            onChanged: (v) {},
                            activeColor: AppColors.primary,
                          ),
                          onTap: () {},
                        ),
                        const Divider(height: 1),
                        _SettingsTile(
                          icon: Icons.help_outline_rounded,
                          label: 'Help & Support',
                          onTap: () => _showComingSoon(context),
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

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coming soon!'), backgroundColor: AppColors.primary),
    );
  }

  void _showEditGoalsDialog(BuildContext context, user) {
    final goalCtrl = TextEditingController(text: '${user?.dailyGoal ?? 20}');
    final accCtrl  = TextEditingController(text: '${user?.goalAccuracy ?? 80}');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditGoalsSheet(goalCtrl: goalCtrl, accCtrl: accCtrl),
    );
  }

  void _showEditProfileDialog(BuildContext context, user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(user: user),
    );
  }
}

// ── Profile Hero Card ────────────────────────────────────────────────────────
class _ProfileHeroCard extends StatelessWidget {
  final dynamic user;
  final Map<String, dynamic> progress;
  const _ProfileHeroCard({required this.user, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
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
                        width: 88, height: 88,
                        errorBuilder: (_, __, ___) => _avatarFallback()))
                    : _avatarFallback(),
              ),
              GestureDetector(
                onTap: () => _pickAvatar(context),
                child: Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 4)],
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(user?.name ?? 'Learner',
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(user?.email ?? '', style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 14)),
          if ((user?.bio ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(user!.bio, style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 13),
                textAlign: TextAlign.center),
          ],
          const SizedBox(height: 16),
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
    );
  }

  Widget _avatarFallback() => Text(
    user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800),
  );

  Future<void> _pickAvatar(BuildContext context) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512);
    if (picked == null || !context.mounted) return;
    // For now, show a URL input dialog instead of file upload
    _showAvatarUrlDialog(context);
  }

  void _showAvatarUrlDialog(BuildContext context) {
    final ctrl = TextEditingController(text: user?.avatar ?? '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: const Text('Update Avatar', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter image URL:', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              decoration: InputDecoration(
                hintText: 'https://...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (ctrl.text.trim().isNotEmpty) {
                await context.read<AuthProvider>().updateProfile(avatar: ctrl.text.trim());
              }
            },
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── Streak Milestones Card ───────────────────────────────────────────────────
class _StreakMilestonesCard extends StatelessWidget {
  final dynamic user;
  const _StreakMilestonesCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final streak = user?.streakDays ?? 0;
    final claimed = user?.streakMilestonesClaimed ?? <int>[];
    final milestones = [
      {'days': 7,   'xp': 100,  'icon': '🔥', 'label': '7-Day Streak'},
      {'days': 30,  'xp': 500,  'icon': '⚡', 'label': '30-Day Streak'},
      {'days': 100, 'xp': 2000, 'icon': '💎', 'label': '100-Day Legend'},
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              const Text('Streak Milestones', style: AppTextStyles.h3),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text('$streak days',
                    style: const TextStyle(color: Colors.deepOrange,
                        fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...() {
            final List<Map<String, dynamic>> visibleMilestones = [];
            bool foundNext = false;
            for (final m in milestones) {
              final days = m['days'] as int;
              final achieved = streak >= days;
              if (achieved) {
                visibleMilestones.add(m);
              } else if (!foundNext) {
                visibleMilestones.add(m);
                foundNext = true;
              }
            }

            return visibleMilestones.map((m) {
              final days = m['days'] as int;
              final xp   = m['xp'] as int;
              final achieved = streak >= days;
              final claimedAlready = (claimed as List).contains(days);
              final progress = (streak / days).clamp(0.0, 1.0);
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: achieved
                            ? Colors.deepOrange.withOpacity(0.15)
                            : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Center(child: Text(m['icon'] as String,
                          style: TextStyle(fontSize: 20,
                              color: achieved ? null : Colors.grey))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(m['label'] as String,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: achieved ? AppColors.textPrimary : AppColors.textSecondary)),
                              const Spacer(),
                              Text('+$xp XP',
                                  style: TextStyle(
                                      fontSize: 12, fontWeight: FontWeight.w700,
                                      color: claimedAlready ? AppColors.success : AppColors.primary)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          AppProgressBar(
                            value: progress,
                            color: achieved ? AppColors.success : AppColors.primary,
                            height: 5,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            claimedAlready
                                ? '✓ Claimed!'
                                : achieved
                                    ? 'Milestone reached!'
                                    : '$streak / $days days',
                            style: TextStyle(
                                fontSize: 11,
                                color: claimedAlready
                                    ? AppColors.success
                                    : achieved ? AppColors.primary : AppColors.textHint),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            });
          }(),
        ],
      ),
    );
  }
}

// ── Edit Profile Bottom Sheet ────────────────────────────────────────────────
class _EditProfileSheet extends StatefulWidget {
  final dynamic user;
  const _EditProfileSheet({required this.user});
  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _bioCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user?.name ?? '');
    _bioCtrl  = TextEditingController(text: widget.user?.bio ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final ok = await context.read<AuthProvider>().updateProfile(
      name: _nameCtrl.text.trim(),
      bio: _bioCtrl.text.trim(),
    );
    setState(() => _saving = false);
    if (ok && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated! ✓'), backgroundColor: AppColors.success),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomPad),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Edit Profile', style: AppTextStyles.h3),
          const SizedBox(height: 20),
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              labelText: 'Full Name',
              prefixIcon: const Icon(Icons.person_outline, color: AppColors.primary, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2)),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _bioCtrl,
            maxLines: 3,
            maxLength: 120,
            decoration: InputDecoration(
              labelText: 'Bio (optional)',
              hintText: 'Tell others about yourself...',
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 42),
                child: Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 20)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2)),
            ),
          ),
          const SizedBox(height: 16),
          GradientButton(
            text: 'Save Changes',
            onTap: _save,
            isLoading: _saving,
            icon: Icons.check_rounded,
          ),
        ],
      ),
    );
  }
}

// ── Edit Goals Bottom Sheet ───────────────────────────────────────────────────
class _EditGoalsSheet extends StatefulWidget {
  final TextEditingController goalCtrl;
  final TextEditingController accCtrl;
  const _EditGoalsSheet({required this.goalCtrl, required this.accCtrl});
  @override
  State<_EditGoalsSheet> createState() => _EditGoalsSheetState();
}

class _EditGoalsSheetState extends State<_EditGoalsSheet> {
  bool _saving = false;

  Future<void> _save() async {
    final goal = int.tryParse(widget.goalCtrl.text);
    final acc  = int.tryParse(widget.accCtrl.text);
    if (goal == null || acc == null) return;
    setState(() => _saving = true);
    final ok = await context.read<AuthProvider>().updateProfile(
      dailyGoal: goal.clamp(5, 100),
      goalAccuracy: acc.clamp(50, 100),
    );
    setState(() => _saving = false);
    if (ok && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Goals updated! ✓'), backgroundColor: AppColors.success),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomPad),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.xl)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Set Learning Goals', style: AppTextStyles.h3),
          const SizedBox(height: 20),
          TextField(
            controller: widget.goalCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Daily Word Goal (5–100)',
              prefixIcon: const Icon(Icons.today_rounded, color: AppColors.primary, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2)),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: widget.accCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Target Accuracy % (50–100)',
              prefixIcon: const Icon(Icons.track_changes_rounded, color: AppColors.secondary, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2)),
            ),
          ),
          const SizedBox(height: 16),
          GradientButton(
            text: 'Save Goals',
            onTap: _save,
            isLoading: _saving,
            icon: Icons.check_rounded,
          ),
        ],
      ),
    );
  }
}

// ── Shared subwidgets ────────────────────────────────────────────────────────
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

class _BadgeChip extends StatelessWidget {
  final String badge;
  const _BadgeChip({required this.badge});
  @override
  Widget build(BuildContext context) {
    const icons = {'7-Day Streak': '🔥', '30-Day Streak': '⚡', '100-Day Legend': '💎',
                   'XP Master': '⚡', 'XP Legend': '🌟'};
    final icon = icons[badge] ?? '🏆';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Text('$icon $badge',
          style: const TextStyle(
              color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }
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
  final Widget? trailing;
  const _SettingsTile({required this.icon, required this.label,
      required this.onTap, this.color, this.trailing});
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: color ?? AppColors.textSecondary, size: 22),
    title: Text(label, style: TextStyle(
        fontWeight: FontWeight.w500,
        color: color ?? AppColors.textPrimary)),
    trailing: trailing ?? Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 20),
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(vertical: 2),
  );
}