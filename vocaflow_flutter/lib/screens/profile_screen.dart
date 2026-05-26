// Profile Screen — full profile management with edit, streak milestones, badges
import 'dart:convert';
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

    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const LingoAppBar(
        title: 'Profile',
        showStreak: false,
        showBackButton: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 32 : 20,
            vertical: isDesktop ? 24 : 16,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isDesktop ? 1024 : 800),
              child: isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column
                        Expanded(
                          flex: 5,
                          child: Column(
                            children: [
                              _ProfileHeroCard(user: user, progress: progress),
                              const SizedBox(height: 20),
                              _BadgesCard(user: user, progress: progress),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Right Column
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildGoalsCard(context, user),
                              const SizedBox(height: 20),

                              _buildSettingsCard(context, user),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _ProfileHeroCard(user: user, progress: progress),
                        const SizedBox(height: 20),
                        _BadgesCard(user: user, progress: progress),
                        const SizedBox(height: 16),
                        _buildGoalsCard(context, user),
                        const SizedBox(height: 16),
                        _buildSettingsCard(context, user),
                        const SizedBox(height: 80),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoalsCard(BuildContext context, user) {
    return AppCard(
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
    );
  }



  Widget _buildSettingsCard(BuildContext context, user) {
    return AppCard(
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
                    ? ClipOval(
                        child: user!.avatar!.startsWith('data:image/')
                            ? Image.memory(
                                base64.decode(user!.avatar!.split(',').last),
                                fit: BoxFit.cover,
                                width: 88,
                                height: 88,
                                errorBuilder: (_, __, ___) => _avatarFallback(),
                              )
                            : Image.network(
                                user!.avatar!,
                                fit: BoxFit.cover,
                                width: 88,
                                height: 88,
                                errorBuilder: (_, __, ___) => _avatarFallback(),
                              ),
                      )
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
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 256,
        maxHeight: 256,
        imageQuality: 60,
      );
      if (picked == null || !context.mounted) return;

      final bytes = await picked.readAsBytes();
      final base64String = 'data:image/png;base64,${base64.encode(bytes)}';

      final auth = context.read<AuthProvider>();
      final ok = await auth.updateProfile(avatar: base64String);

      if (ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar updated successfully! ✓'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update avatar: $e'), backgroundColor: AppColors.error),
        );
      }
    }
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

class _BadgesCard extends StatelessWidget {
  final dynamic user;
  final Map<String, dynamic> progress;
  
  const _BadgesCard({required this.user, required this.progress});

  @override
  Widget build(BuildContext context) {
    final bool hasStreak7 = user?.badges.contains('7-Day Streak') == true || (user?.streakDays ?? 0) >= 7;
    final bool hasStreak30 = user?.badges.contains('30-Day Streak') == true || (user?.streakDays ?? 0) >= 30;
    final bool hasXPMaster = user?.badges.contains('XP Master') == true || (user?.totalXP ?? 0) >= 1000;

    final badgeDefs = [
      {
        'key': '7-Day Streak',
        'title': 'Streak Hunter I',
        'desc': 'Maintain a 7-day learning streak',
        'icon': '🔥',
        'unlocked': hasStreak7,
        'progressText': '${(user?.streakDays ?? 0).clamp(0, 7)} / 7 days',
        'progressVal': ((user?.streakDays ?? 0) / 7).clamp(0.0, 1.0),
      },
      if (hasStreak7)
        {
          'key': '30-Day Streak',
          'title': 'Streak Hunter II',
          'desc': 'Maintain a 30-day learning streak',
          'icon': '⚡',
          'unlocked': hasStreak30,
          'progressText': '${(user?.streakDays ?? 0).clamp(0, 30)} / 30 days',
          'progressVal': ((user?.streakDays ?? 0) / 30).clamp(0.0, 1.0),
        },
      if (hasStreak30)
        {
          'key': '100-Day Streak',
          'title': '100-Day Legend',
          'desc': 'Maintain a 100-day learning streak',
          'icon': '💎',
          'unlocked': user?.badges.contains('100-Day Streak') == true || user?.badges.contains('100-Day Legend') == true || (user?.streakDays ?? 0) >= 100,
          'progressText': '${(user?.streakDays ?? 0).clamp(0, 100)} / 100 days',
          'progressVal': ((user?.streakDays ?? 0) / 100).clamp(0.0, 1.0),
        },
      {
        'key': 'XP Master',
        'title': 'XP Master I',
        'desc': 'Accumulate 1,000 total XP',
        'icon': '👑',
        'unlocked': hasXPMaster,
        'progressText': '${(user?.totalXP ?? 0).clamp(0, 1000)} / 1,000 XP',
        'progressVal': ((user?.totalXP ?? 0) / 1000).clamp(0.0, 1.0),
      },
      if (hasXPMaster)
        {
          'key': 'XP Legend',
          'title': 'XP Master II',
          'desc': 'Accumulate 5,000 total XP',
          'icon': '🌟',
          'unlocked': user?.badges.contains('XP Legend') == true || (user?.totalXP ?? 0) >= 5000,
          'progressText': '${(user?.totalXP ?? 0).clamp(0, 5000)} / 5,000 XP',
          'progressVal': ((user?.totalXP ?? 0) / 5000).clamp(0.0, 1.0),
        },
      {
        'key': 'Vocab Master',
        'title': 'Vocab Master',
        'desc': 'Master 100 vocabulary words',
        'icon': '📚',
        'unlocked': user?.badges.contains('Vocab Master') == true || (progress['totalMastered'] ?? 0) >= 100,
        'progressText': '${(progress['totalMastered'] ?? 0).clamp(0, 100)} / 100 words',
        'progressVal': ((progress['totalMastered'] ?? 0) / 100).clamp(0.0, 1.0),
      },
      {
        'key': 'AI Bookworm',
        'title': 'AI Bookworm',
        'desc': 'Complete 10 AI stories & quizzes',
        'icon': '🧠',
        'unlocked': user?.badges.contains('AI Bookworm') == true,
        'progressText': user?.badges.contains('AI Bookworm') == true ? '10 / 10 stories' : 'Complete AI quizzes',
        'progressVal': user?.badges.contains('AI Bookworm') == true ? 1.0 : 0.0,
      },
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🏆', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text('Badges & Achievements', style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: badgeDefs.length,
            itemBuilder: (context, index) {
              final b = badgeDefs[index];
              final bool unlocked = b['unlocked'] as bool;
              final double val = b['progressVal'] as double;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    // Badge Circle
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: unlocked
                            ? AppColors.primary.withOpacity(0.12)
                            : Colors.grey.shade100,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: unlocked
                              ? AppColors.primary.withOpacity(0.2)
                              : Colors.grey.shade300,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Opacity(
                          opacity: unlocked ? 1.0 : 0.4,
                          child: Text(
                            b['icon'] as String,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    
                    // Details & Progress
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                b['title'] as String,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14.5,
                                  color: unlocked
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary,
                                ),
                              ),
                              if (unlocked)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    '✓ Unlocked',
                                    style: TextStyle(
                                      color: AppColors.success,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                )
                              else
                                const Text(
                                  '🔒 Locked',
                                  style: TextStyle(
                                    color: AppColors.textHint,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            b['desc'] as String,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: AppProgressBar(
                                  value: val,
                                  color: unlocked ? AppColors.primary : Colors.grey.shade300,
                                  height: 5,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                b['progressText'] as String,
                                style: TextStyle(
                                  color: unlocked ? AppColors.primary : AppColors.textHint,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
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