// Learn Screen — Step 1: Choose Level + Source
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/learn_provider.dart';
import '../providers/word_provider.dart';
import '../core/constants/app_constants.dart';
import '../services/api_service.dart';
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
            LingoAppBar(streak: auth.user?.streakDays ?? 0, showBackButton: false, showStreak: true),

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
                        const SizedBox(height: 16),
                        _buildAIDeckBanner(context),
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
                        const SectionHeader(
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
    mainAxisExtent: 190,
  ),
  children: wordP.sources.map((srcData) {
    final src = srcData['source'] as String;
    final isSelected = learnP.selectedSource == src;
    final total      = srcData['total'] ?? 0;
    final learned    = srcData['learned'] ?? 0;
    final pct        = srcData['percentage'] ?? 0;

    final icon = _sourceIcons[src] ?? Icons.auto_awesome_rounded;
    final desc = _sourceDescriptions[src] ?? 'AI-generated personalized deck';

    return _SourceCard(
      source:      src,
      description: desc,
      icon:        icon,
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

  Widget _buildAIDeckBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF06B6D4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('✨', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'AI DECK GENERATOR',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Generate custom vocabulary cards instantly.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _showAIDeckDialog(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.full),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Text(
                'Generate',
                style: TextStyle(
                  color: Color(0xFF4F46E5),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAIDeckDialog(BuildContext context) {
    final topicCtrl = TextEditingController();
    String selectedLvl = _selectedLevel;
    bool isGenerating = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          if (isGenerating) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 24),
                  const Text(
                    'AI is generating vocabulary... ✨',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Analyzing topic "${topicCtrl.text.trim()}" and designing 8 learning cards aligned to CEFR $selectedLvl. Please wait a moment!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Text('✨', style: TextStyle(fontSize: 22)),
                SizedBox(width: 8),
                Text('AI Vocabulary Deck', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Study Topic:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                TextField(
                  controller: topicCtrl,
                  decoration: InputDecoration(
                    hintText: 'e.g. Space exploration, Cooking...',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Target Level (CEFR):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _levels.map((lvl) {
                    final isSel = selectedLvl == lvl;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedLvl = lvl),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.primary : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: isSel ? AppColors.primary : Colors.grey.shade200),
                        ),
                        child: Text(
                          lvl,
                          style: TextStyle(color: isSel ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final topic = topicCtrl.text.trim();
                  if (topic.isEmpty) return;
                  
                  setDialogState(() {
                    isGenerating = true;
                  });

                  try {
                    final apiService = ApiService();
                    final response = await apiService.generateAIDeck(topic, level: selectedLvl);
                    
                    if (response.statusCode == 200 || response.statusCode == 201) {
                      if (context.mounted) {
                        Navigator.pop(context); // Close dialog
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('AI Deck created successfully! 🎉'), backgroundColor: AppColors.success),
                        );
                        // Reload sources for current level
                        setState(() {
                          _selectedLevel = selectedLvl;
                        });
                        context.read<LearnProvider>().selectLevel(selectedLvl);
                        await context.read<WordProvider>().loadSources(level: selectedLvl);
                        
                        // Auto-select the newly generated AI deck
                        context.read<LearnProvider>().selectSource('AI Generated');
                      }
                    } else {
                      throw Exception('Failed to generate');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.pop(context); // Close dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Connection error or failed to create AI vocabulary deck.'), backgroundColor: AppColors.error),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
                child: const Text('Generate'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SourceCard extends StatefulWidget {
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
  State<_SourceCard> createState() => _SourceCardState();
}

class _SourceCardState extends State<_SourceCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()..scale(_isHovered ? 1.03 : 1.0),
          transformAlignment: Alignment.center,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: widget.isSelected
                  ? AppColors.primary
                  : (_isHovered ? AppColors.primary.withOpacity(0.5) : Colors.grey.shade100),
              width: widget.isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isSelected
                    ? AppColors.primary.withOpacity(0.15)
                    : (_isHovered ? Colors.black.withOpacity(0.08) : Colors.black.withOpacity(0.04)),
                blurRadius: _isHovered ? 16 : 12,
                offset: _isHovered ? const Offset(0, 6) : const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        child: Icon(widget.icon, color: AppColors.primary, size: 24),
                      ),
                      const Spacer(),
                      if (widget.isSelected)
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
                  Text(widget.source,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(widget.description,
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
                        '${widget.masteredWords} / ${widget.totalWords} Words',
                        style: AppTextStyles.bodySmall,
                      ),
                      const Spacer(),
                      Text(
                        '${widget.percentage}%',
                        style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700,
                          color: widget.percentage >= 80 ? AppColors.success : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AppProgressBar(
                    value: widget.percentage / 100,
                    color: widget.percentage >= 80 ? AppColors.success : AppColors.primary,
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