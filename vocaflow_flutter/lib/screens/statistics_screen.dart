// Statistics Screen — full learning analytics
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart'; // Đảm bảo đã thêm intl vào pubspec.yaml để định dạng ngày tháng
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

    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => context.read<StatsProvider>().loadDashboard(),
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 32 : 20,
              vertical: isDesktop ? 24 : 16,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isDesktop ? 1024 : 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Learning Stats', style: AppTextStyles.h2),
                    Text('Your progress this week.', style: AppTextStyles.bodySmall),
                    const SizedBox(height: 24),
                    isDesktop
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left column
                              Expanded(
                                flex: 6,
                                child: Column(
                                  children: [
                                    _buildWeeklyChart(stats, weekly),
                                    const SizedBox(height: 20),
                                    _buildHeatmapCard(heatmap),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),
                              // Right column
                              Expanded(
                                flex: 4,
                                child: Column(
                                  children: [
                                    _buildSummaryRow(progress),
                                    const SizedBox(height: 20),
                                    _buildStudyTime(study),
                                    if (badges.isNotEmpty) ...[
                                      const SizedBox(height: 20),
                                      _buildRecentBadgesCard(badges),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildWeeklyChart(stats, weekly),
                              const SizedBox(height: 16),
                              _buildSummaryRow(progress),
                              const SizedBox(height: 16),
                              _buildStudyTime(study),
                              const SizedBox(height: 16),
                              _buildHeatmapCard(heatmap),
                              if (badges.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                _buildRecentBadgesCard(badges),
                              ],
                              const SizedBox(height: 80),
                            ],
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyChart(stats, List<Map<String, dynamic>> weekly) {
    return AppCard(
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
          const SizedBox(height: 24),
          SizedBox(
            height: 140,
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
                                .reduce((a, b) => a > b ? a : b) + 30),
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipColor: (group) => Colors.grey.shade900,
                            tooltipRoundedRadius: 8,
                            tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            tooltipMargin: 6,
                            fitInsideHorizontally: true,
                            fitInsideVertically: true,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                '${rod.toY.toInt()} XP',
                                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              );
                            },
                          ),
                        ),
                        barGroups: weekly.asMap().entries.map((e) {
                          final today = DateTime.now();
                          final dayName = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][today.weekday - 1];
                          final isToday = e.value['day'] == dayName;
                          return BarChartGroupData(
                            x: e.key,
                            barRods: [
                              BarChartRodData(
                                toY: (e.value['xp'] as int? ?? 0).toDouble(),
                                color: isToday ? AppColors.primary : AppColors.primary.withOpacity(0.35),
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
                                final dayName = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][today.weekday - 1];
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(day,
                                      style: TextStyle(
                                        fontSize: 12, fontWeight: FontWeight.w600,
                                        color: day == dayName ? AppColors.primary : AppColors.textSecondary,
                                      )),
                                );
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
    );
  }

  Widget _buildSummaryRow(progress) {
    return Row(
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
    );
  }

  Widget _buildStudyTime(study) {
    return Container(
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
    );
  }

  Widget _buildHeatmapCard(heatmap) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Activity Heatmap',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              Text('Last 4 Weeks',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          _EnhancedHeatmapGrid(heatmap: heatmap),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text('Less', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              const SizedBox(width: 6),
              ...List.generate(4, (i) => Container(
                width: 12, height: 12,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15 + i * 0.25),
                  borderRadius: BorderRadius.circular(3),
                ),
              )),
              const Text('More', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentBadgesCard(List<String> badges) {
    return AppCard(
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
    );
  }
}

class _EnhancedHeatmapGrid extends StatelessWidget {
  final Map<String, dynamic> heatmap;
  const _EnhancedHeatmapGrid({required this.heatmap});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    
    // Tìm ngày Thứ 2 của 3 tuần trước để tạo thành một bảng lưới 4 tuần hoàn chỉnh (28 ngày)
    final int daysToSubtract = (now.weekday - 1) + 21; 
    final startDate = now.subtract(Duration(days: daysToSubtract));

    List<DateTime> gridDates = List.generate(28, (i) => startDate.add(Duration(days: i)));
    
    int maxVal = 1;
    for (var date in gridDates) {
      final key = date.toIso8601String().split('T')[0];
      final val = (heatmap[key] as int?) ?? 0;
      if (val > maxVal) maxVal = val;
    }

    final weekLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: weekLabels.map((label) => Expanded(
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600, 
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          )).toList(),
        ),
        const SizedBox(height: 10),
        
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 28,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7, 
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
          ),
          itemBuilder: (context, index) {
            final date = gridDates[index];
            final key = date.toIso8601String().split('T')[0];
            final value = (heatmap[key] as int?) ?? 0;
            final intensity = value / maxVal;
            
            final isFuture = date.isAfter(now);

            return GestureDetector(
              onTap: isFuture ? null : () {
                final dateStr = "${date.day}/${date.month}";
                final learnedStr = value > 0 ? "Bạn đã học $value từ vựng" : "Chưa học từ vựng nào";
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
                    backgroundColor: value > 0 ? AppColors.primary : AppColors.textSecondary,
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
                delay: Duration(milliseconds: 12 * index), // Staggered loading!
                child: Tooltip(
                  message: '${DateFormat('dd/MM/yyyy').format(date)}: ${value} bài học',
                  preferBelow: false,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isFuture
                          ? Colors.transparent 
                          : (value == 0
                              ? Colors.grey.shade100 
                              : AppColors.primary.withOpacity(0.25 + intensity * 0.75)), 
                      borderRadius: BorderRadius.circular(6), // Slightly rounder (6 instead of 4) for premium look
                      border: date.day == now.day && date.month == now.month && date.year == now.year
                          ? Border.all(color: AppColors.primary, width: 1.5) 
                          : (value == 0 && !isFuture ? Border.all(color: Colors.grey.shade200, width: 0.5) : null),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
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
          width: 56, height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: (data['color'] as Color).withOpacity(0.4), width: 2),
            color: (data['color'] as Color).withOpacity(0.08),
          ),
          child: Center(child: Text(data['icon'] as String, style: const TextStyle(fontSize: 24))),
        ),
        const SizedBox(height: 6),
        Text(badge, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
      ],
    );
  }
}