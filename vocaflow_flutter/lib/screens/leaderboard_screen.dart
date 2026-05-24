// Leaderboard Screen — streak & XP rankings
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/stats_provider.dart';
import '../services/api_service.dart';
import '../core/constants/app_constants.dart';
import 'widgets/shared_widgets.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});
  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthProvider>().user?.id ?? '';
    final stats = context.watch<StatsProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Leaderboard', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: AppColors.background,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: TabBar(
                controller: _tabCtrl,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                tabs: const [
                  Tab(icon: Icon(Icons.local_fire_department_rounded), text: 'Streak'),
                  Tab(icon: Icon(Icons.bolt_rounded), text: 'XP'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: stats.isLoading && stats.leaderboard.isEmpty
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _LeaderboardContent(type: 'streak', currentUserId: currentUserId),
                    _LeaderboardContent(type: 'xp', currentUserId: currentUserId),
                  ],
                ),
        ),
      ),
    );
  }
}

class _LeaderboardContent extends StatefulWidget {
  final String type;
  final String currentUserId;
  const _LeaderboardContent({required this.type, required this.currentUserId});

  @override
  State<_LeaderboardContent> createState() => _LeaderboardContentState();
}

class _LeaderboardContentState extends State<_LeaderboardContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StatsProvider>().loadLeaderboard(sortBy: widget.type);
    });
  }

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<StatsProvider>();
    if (stats.isLoading) return const Center(child: CircularProgressIndicator());
    
    return _LeaderboardList(
      entries: stats.leaderboard,
      type: widget.type,
      myRank: stats.myRank?['rank'],
      currentUserId: widget.currentUserId,
      onRefresh: () => stats.loadLeaderboard(sortBy: widget.type),
    );
  }
}

class _LeaderboardList extends StatelessWidget {
  final List<dynamic> entries;
  final String type;
  final int? myRank;
  final String currentUserId;
  final Future<void> Function() onRefresh;

  const _LeaderboardList({
    required this.entries,
    required this.type,
    required this.myRank,
    required this.currentUserId,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final showPodium = entries.length >= 3;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: RefreshIndicator(
          onRefresh: onRefresh,
          color: AppColors.primary,
          child: entries.isEmpty
              ? _buildEmptyState()
              : CustomScrollView(
                  slivers: [
                    // Top 3 podium
                    if (showPodium)
                      SliverToBoxAdapter(child: _PodiumWidget(entries: entries, type: type)),

                    // My rank banner (if not in top 20)
                    if (myRank != null && myRank! > 20)
                      SliverToBoxAdapter(
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.person_rounded, color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              Text('Your rank: #$myRank',
                                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                              const Spacer(),
                              const Text('Keep learning to climb! 🚀',
                                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ),

                    // Full list (skip top 3 only if shown in podium)
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) {
                          final entry = entries[i];
                          final rank  = entry['rank'] as int;
                          final isMe  = entry['_id']?.toString() == currentUserId;
                          if (showPodium && rank <= 3) return const SizedBox.shrink();
                          return _LeaderboardTile(entry: entry, type: type, isMe: isMe);
                        },
                        childCount: entries.length,
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 80)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.leaderboard_rounded,
                  size: 60,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'No ranking entries yet!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Start learning to be the first on the board! 🏆',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PodiumWidget extends StatelessWidget {
  final List<dynamic> entries;
  final String type;
  const _PodiumWidget({required this.entries, required this.type});

  @override
  Widget build(BuildContext context) {
    final first  = entries[0];
    final second = entries[1];
    final third  = entries[2];

    String val(Map e) => type == 'streak'
        ? '🔥 ${e['streakDays']}d'
        : '⚡ ${e['totalXP']} XP';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _PodiumPillar(entry: second, rank: 2, height: 80, valueFn: val),
          _PodiumPillar(entry: first,  rank: 1, height: 110, valueFn: val),
          _PodiumPillar(entry: third,  rank: 3, height: 60,  valueFn: val),
        ],
      ),
    );
  }
}

class _PodiumPillar extends StatelessWidget {
  final dynamic entry;
  final int rank;
  final double height;
  final String Function(Map) valueFn;
  const _PodiumPillar({required this.entry, required this.rank,
      required this.height, required this.valueFn});

  @override
  Widget build(BuildContext context) {
    final medals = {1: '🥇', 2: '🥈', 3: '🥉'};
    final name   = (entry['name'] as String? ?? 'User');
    final avatar = entry['avatar'] as String?;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(medals[rank]!, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        CircleAvatar(
          radius: rank == 1 ? 28 : 22,
          backgroundColor: Colors.white.withOpacity(0.2),
          backgroundImage: avatar != null ? NetworkImage(avatar) : null,
          child: avatar == null
              ? Text(name[0].toUpperCase(),
                  style: TextStyle(color: Colors.white,
                      fontSize: rank == 1 ? 20 : 16, fontWeight: FontWeight.w800))
              : null,
        ),
        const SizedBox(height: 6),
        Text(name.split(' ').first,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(valueFn(Map.from(entry)),
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          width: 60, height: height,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          alignment: Alignment.center,
          child: Text('#$rank',
              style: const TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w800, fontSize: 18)),
        ),
      ],
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  final dynamic entry;
  final String type;
  final bool isMe;
  const _LeaderboardTile({required this.entry, required this.type, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final rank   = entry['rank'] as int;
    final name   = entry['name'] as String? ?? 'User';
    final avatar = entry['avatar'] as String?;
    final value  = type == 'streak'
        ? '🔥 ${entry['streakDays']}d'
        : '⚡ ${entry['totalXP']} XP';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? AppColors.primary.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isMe ? AppColors.primary.withOpacity(0.25) : Colors.grey.shade100,
          width: isMe ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03),
              blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text('#$rank',
                style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 14,
                    color: isMe ? AppColors.primary : AppColors.textSecondary)),
          ),
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            backgroundImage: avatar != null ? NetworkImage(avatar) : null,
            child: avatar == null
                ? Text(name[0].toUpperCase(),
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isMe ? AppColors.primary : AppColors.textPrimary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                if (isMe)
                  const Text('You', style: TextStyle(
                      fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
