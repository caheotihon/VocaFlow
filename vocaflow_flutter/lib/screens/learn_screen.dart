// Learn Screen — Step 1: Choose Level + Source
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/learn_provider.dart';
import '../providers/word_provider.dart';
import '../core/constants/app_constants.dart';
import 'widgets/shared_widgets.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});
  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  final List<String> _levels = ['A1', 'A2', 'B1', 'B2', 'C1'];
  String _selectedLevel = 'B1';

  static const _sourceIcons = {
    'Oxford 5000':     Icons.menu_book_rounded,
    'Oxford 3000':     Icons.book_outlined,
    'Cambridge B1/B2': Icons.school_outlined,
    'IELTS Core':      Icons.assignment_outlined,
    'TOEIC Core':      Icons.business_center_outlined,
  };

  static const _sourceDescriptions = {
    'Oxford 5000':     'Essential English vocabulary',
    'Oxford 3000':     'Core vocabulary foundation',
    'Cambridge B1/B2': 'Exam preparation',
    'IELTS Core':      'Academic vocabulary',
    'TOEIC Core':      'Business English',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lp = context.read<LearnProvider>();
      final initialLevel = lp.selectedLevel ?? 'B1';
      setState(() => _selectedLevel = initialLevel);
      context.read<WordProvider>().loadSources(level: initialLevel);
    });
  }

  @override
  Widget build(BuildContext context) {
    final wordP  = context.watch<WordProvider>();
    final learnP = context.watch<LearnProvider>();
    final auth   = context.watch<AuthProvider>();

    // Tính toán kích thước màn hình
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;
    final isTablet = width >= 600 && width < 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── App bar ────────────────────────────────────────────
            LingoAppBar(streak: auth.user?.streakDays ?? 0),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                // Căn giữa và giới hạn kích thước cho màn hình lớn
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Learn Vocabulary', style: AppTextStyles.h1),
                        const SizedBox(height: 4),
                        Text('Select your level and source to begin.',
                            style: AppTextStyles.bodySmall),
                        const SizedBox(height: 28),

                        // ── Choose Level ───────────────────────────────
                        const SectionHeader(title: 'Choose Level'),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10, runSpacing: 10,
                          children: _levels.map((lvl) => LevelChip(
                            level: lvl,
                            isSelected: _selectedLevel == lvl,
                            onTap: () {
                              setState(() => _selectedLevel = lvl);
                              learnP.selectLevel(lvl);
                              context.read<WordProvider>().loadSources(level: lvl);
                            },
                          )).toList(),
                        ),
                        const SizedBox(height: 32),

                        // ── Choose Source ──────────────────────────────
                        SectionHeader(
                          title: 'Choose Learning Source'
                        ),
                        const SizedBox(height: 16),

                        if (wordP.isLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: CircularProgressIndicator(color: AppColors.primary),
                            ),
                          )
                        else
                          // Thay Column bằng GridView responsive
                          // Thay thế đoạn GridView.count cũ bằng GridView với gridDelegate
GridView(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: isDesktop ? 3 : (isTablet ? 2 : 1),
    crossAxisSpacing: 16,
    mainAxisSpacing: 16,
    // SỬ DỤNG MAIN AXIS EXTENT ĐỂ CỐ ĐỊNH CHIỀU CAO CARD
    mainAxisExtent: 190, // Chiều cao cố định 190px (hoặc tùy chỉnh 180-200)
  ),
  children: _sourceIcons.keys.map((src) {
    final srcData = wordP.sources.firstWhere(
      (s) => s['source'] == src,
      orElse: () => {'source': src, 'total': 0, 'mastered': 0, 'percentage': 0},
    );
    final isSelected = learnP.selectedSource == src;
    final total      = srcData['total'] ?? 0;
    final learned    = srcData['learned'] ?? 0;
    final pct        = srcData['percentage'] ?? 0;

    return _SourceCard(
      source:      src,
      description: _sourceDescriptions[src]!,
      icon:        _sourceIcons[src]!,
      totalWords:  total,
      masteredWords:  learned,
      percentage:  pct,
      isSelected:  isSelected,
      onTap: () {
        learnP.selectSource(src);
        learnP.selectLevel(_selectedLevel);
      },
    );
  }).toList(),
),

                        const SizedBox(height: 80), // Khoảng trống cuộn
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Continue button ─────────────────────────────────────
            if (learnP.selectedSource != null)
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    // Trên Desktop/Tablet căn nút sang phải, Mobile full width
                    alignment: isDesktop || isTablet ? Alignment.centerRight : Alignment.center,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isDesktop || isTablet ? 280 : double.infinity,
                      ),
                      child: GradientButton(
                        text: 'Continue Learning',
                        icon: Icons.arrow_forward_rounded,
                        onTap: () => Navigator.pushNamed(context, '/select-topic'),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  final String source, description;
  final IconData icon;
  final int totalWords, masteredWords, percentage;
  final bool isSelected;
  final VoidCallback onTap;

  const _SourceCard({
    required this.source, required this.description, required this.icon,
    required this.totalWords, required this.masteredWords, required this.percentage,
    required this.isSelected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click, // Hiển thị con trỏ tay chỉ trên Web/Desktop
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey.shade100,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.12)
                    : Colors.black.withOpacity(0.04),
                blurRadius: 12, offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Tối ưu phân bổ không gian trong Grid
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: AppColors.primary, size: 24),
                      ),
                      const Spacer(),
                      if (isSelected)
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_circle,
                              color: AppColors.primary, size: 20),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(source,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(description, 
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall),
                ],
              ),
              
              // Bottom Progress Info
              Column(
                children: [
                  Row(
                    children: [
                      Text(
                        '$masteredWords / $totalWords Words',
                        style: AppTextStyles.bodySmall,
                      ),
                      const Spacer(),
                      Text(
                        '$percentage%',
                        style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700,
                          color: percentage >= 80 ? AppColors.success : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AppProgressBar(
                    value: percentage / 100,
                    color: percentage >= 80 ? AppColors.success : AppColors.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}