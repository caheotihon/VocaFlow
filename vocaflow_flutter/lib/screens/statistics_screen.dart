// Statistics Screen — full learning analytics
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/stats_provider.dart';
import '../core/constants/app_constants.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'widgets/shared_widgets.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});
  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StatsProvider>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<StatsProvider>();
    final dash  = stats.dashboard;
    final weekly = (dash?['weeklyData'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final progress = dash?['progress'] as Map<String, dynamic>? ?? {};
    final study    = dash?['study']    as Map<String, dynamic>? ?? {};
    final badges   = (dash?['user']?['badges'] as List?)?.cast<String>() ?? [];
    final heatmap  = (dash?['heatmap'] as Map<String, dynamic>?)?.cast<String, dynamic>() ?? {};

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => context.read<StatsProvider>().loadDashboard(),
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Learning Stats', style: AppTextStyles.h2),
                    Text('Your progress this week.', style: AppTextStyles.bodySmall),
                    const SizedBox(height: 24),

                    // ── Weekly Bar Chart ─────────────────────────────────
                    AppCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('XP Progress',
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                              Text('This Week',
                                  style: const TextStyle(
                                    color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 120,
                            child: stats.isLoading
                                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                                : Animate(
                                    effects: const [
                                      FadeEffect(duration: Duration(milliseconds: 600)),
                                      ScaleEffect(duration: Duration(milliseconds: 500), curve: Curves.easeOutBack, begin: Offset(0.95, 0.8)),
                                    ],
                                    child: BarChart(
                                      BarChartData(
                                        alignment: BarChartAlignment.spaceAround,
                                        maxY: weekly.isEmpty ? 10 :
                                            (weekly.map((d) => (d['xp'] as int? ?? 0).toDouble())
                                                .reduce((a, b) => a > b ? a : b) + 20),
                                        barGroups: weekly.asMap().entries.map((e) {
                                          final today = DateTime.now();
                                          final dayName = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun']
                                              [today.weekday - 1];
                                          final isToday = e.value['day'] == dayName;
                                          return BarChartGroupData(
                                            x: e.key,
                                            barRods: [
                                              BarChartRodData(
                                                toY: (e.value['xp'] as int? ?? 0).toDouble(),
                                                gradient: isToday
                                                    ? const LinearGradient(
                                                        colors: [AppColors.primary, AppColors.secondary],
                                                        begin: Alignment.bottomCenter,
                                                        end: Alignment.topCenter,
                                                      )
                                                    : LinearGradient(
                                                        colors: [AppColors.primary.withOpacity(0.35), AppColors.secondary.withOpacity(0.2)],
                                                        begin: Alignment.bottomCenter,
                                                        end: Alignment.topCenter,
                                                      ),
                                                width: 18,
                                                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                        gridData: const FlGridData(show: false),
                                        borderData: FlBorderData(show: false),
                                        titlesData: FlTitlesData(
                                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                          bottomTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              getTitlesWidget: (val, _) {
                                                final idx = val.toInt();
                                                final day = weekly.isNotEmpty && idx < weekly.length
                                                    ? weekly[idx]['day'] as String? ?? '' : '';
                                                final today = DateTime.now();
                                                final dayName = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun']
                                                    [today.weekday - 1];
                                                return Text(day,
                                                    style: TextStyle(
                                                      fontSize: 12, fontWeight: FontWeight.w600,
                                                      color: day == dayName ? AppColors.primary : AppColors.textSecondary,
                                                    ));
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Words mastered + Accuracy ─────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.school_outlined, color: AppColors.primary, size: 20),
                                    const SizedBox(width: 6),
                                    const Text('Words\nMastered', style: AppTextStyles.bodySmall),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '${progress['totalMastered'] ?? 0}',
                                  style: const TextStyle(
                                    fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
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
                                Row(
                                  children: [
                                    Icon(Icons.track_changes, color: AppColors.secondary, size: 20),
                                    const SizedBox(width: 6),
                                    const Text('Accuracy', style: AppTextStyles.bodySmall),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '${progress['accuracy'] ?? 0}%',
                                  style: const TextStyle(
                                    fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Total Study Time ──────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_rounded, color: Colors.white, size: 24),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total Study Time',
                                  style: TextStyle(color: Colors.white70, fontSize: 13)),
                              Text('${study['totalStudyHours'] ?? 0}h',
                                  style: const TextStyle(
                                    color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.trending_up_rounded,
                                color: Colors.white, size: 22),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Activity Heatmap ──────────────────────────────────
                    AppCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Activity Heatmap',
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                              Text('Last 30 Days',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _HeatmapGrid(heatmap: heatmap),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Text('Less', style: AppTextStyles.bodySmall),
                              const SizedBox(width: 6),
                              ...List.generate(4, (i) => Container(
                                width: 14, height: 14,
                                margin: const EdgeInsets.only(right: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.15 + i * 0.25),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              )),
                              const Text('More', style: AppTextStyles.bodySmall),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Badges ────────────────────────────────────────────
                    if (badges.isNotEmpty) ...[
                      AppCard(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Recent Badges',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: Wrap(
                                spacing: 24,
                                runSpacing: 16,
                                alignment: WrapAlignment.center,
                                children: badges.map((b) => _BadgeItem(badge: b)).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeatmapGrid extends StatelessWidget {
  final Map<String, dynamic> heatmap;
  const _HeatmapGrid({required this.heatmap});

  @override
  Widget build(BuildContext context) {
    final now   = DateTime.now();
    
    // Create lists of days and the values
    final List<Map<String, dynamic>> cells = List.generate(30, (i) {
      final date = now.subtract(Duration(days: 29 - i));
      final key  = date.toIso8601String().split('T')[0];
      final val  = (heatmap[key] as int?) ?? 0;
      return {'date': date, 'val': val};
    });

    final counts = cells.map((c) => c['val'] as int).toList();
    int maxVal = counts.isEmpty ? 1 : counts.reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) maxVal = 1;

    return GridView.count(
      crossAxisCount: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 5,
      mainAxisSpacing: 5,
      children: cells.asMap().entries.map((entry) {
        final idx = entry.key;
        final cell = entry.value;
        final v = cell['val'] as int;
        final dt = cell['date'] as DateTime;
        final intensity = v / maxVal;

        return GestureDetector(
          onTap: () {
            final dateStr = "${dt.day}/${dt.month}";
            final learnedStr = v > 0 ? "Bạn đã học $v từ vựng" : "Chưa học từ vựng nào";
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Text('🗓️ ', style: TextStyle(fontSize: 16)),
                    Text(
                      "Ngày $dateStr: $learnedStr!",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                duration: const Duration(seconds: 2),
                backgroundColor: v > 0 ? AppColors.primary : AppColors.textSecondary,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          },
          child: Animate(
            effects: [
              FadeEffect(duration: const Duration(milliseconds: 250)),
              ScaleEffect(duration: const Duration(milliseconds: 250), curve: Curves.easeOut),
            ],
            delay: Duration(milliseconds: 12 * idx), // Staggered loading!
            child: Container(
              decoration: BoxDecoration(
                color: v == 0
                    ? Colors.grey.shade100
                    : AppColors.primary.withOpacity(0.2 + intensity * 0.8),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: v == 0 ? Colors.grey.shade200 : AppColors.primary.withOpacity(0.4),
                  width: 1,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _BadgeItem extends StatelessWidget {
  final String badge;
  const _BadgeItem({required this.badge});

  @override
  Widget build(BuildContext context) {
    final Map<String, Map<String, dynamic>> badgeData = {
      '7-Day Streak': {'icon': '🔥', 'color': Colors.orange},
      'XP Master':    {'icon': '⚡', 'color': AppColors.primary},
      'Early Bird':   {'icon': '🌅', 'color': Colors.amber},
      'Vocab Master': {'icon': '💎', 'color': AppColors.secondary},
    };
    final data = badgeData[badge] ?? {'icon': '🏆', 'color': AppColors.primary};

    return Column(
      children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: (data['color'] as Color).withOpacity(0.5), width: 2),
            color: (data['color'] as Color).withOpacity(0.08),
          ),
          child: Center(child: Text(data['icon'] as String,
              style: const TextStyle(fontSize: 28))),
        ),
        const SizedBox(height: 6),
        Text(badge,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }
}
