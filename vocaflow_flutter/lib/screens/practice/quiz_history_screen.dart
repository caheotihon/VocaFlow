// Quiz History Screen — displays completed sessions list
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../core/constants/app_constants.dart';
import '../widgets/shared_widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

class QuizHistoryScreen extends StatefulWidget {
  const QuizHistoryScreen({super.key});

  @override
  State<QuizHistoryScreen> createState() => _QuizHistoryScreenState();
}

class _QuizHistoryScreenState extends State<QuizHistoryScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _sessions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await _api.getSessionHistory();
      if (res.data['success'] == true) {
        setState(() {
          _sessions = res.data['data']['sessions'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = res.data['message'] ?? 'Failed to load history';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Connection error. Please try again later.';
        _isLoading = false;
      });
    }
  }

  Future<void> _viewSessionDetails(String sessionId) async {
    // Show a premium loading indicator overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text(
                'Retrieving details...',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final res = await _api.getSessionDetails(sessionId);
      if (mounted) Navigator.pop(context); // Dismiss loading overlay

      if (res.data['success'] == true) {
        final data = Map<String, dynamic>.from(res.data['data']);
        data['fromHistory'] = true; // Flag to modify UI on ResultScreen

        if (mounted) {
          Navigator.pushNamed(
            context,
            '/result',
            arguments: data,
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res.data['message'] ?? 'Failed to load session details'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Dismiss loading overlay
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to connect to the server.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const LingoAppBar(
        title: 'Practice History',
        showStreak: false,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: RefreshIndicator(
              onRefresh: _fetchHistory,
              color: AppColors.primary,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _error != null
                      ? _buildErrorPlaceholder()
                      : _sessions.isEmpty
                          ? _buildEmptyState()
                          : _buildHistoryList(isDesktop),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 72, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(_error!, style: AppTextStyles.body, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            GradientButton(
              text: 'Try Again',
              icon: Icons.refresh_rounded,
              onTap: _fetchHistory,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 80.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assignment_turned_in_outlined,
                size: 72,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No practice history found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your completed practice sessions will be listed here. Complete your first session now!',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            GradientButton(
              text: 'Start Learning Now',
              icon: Icons.play_arrow_rounded,
              onTap: () {
                Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(bool isDesktop) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: isDesktop ? 24 : 16,
      ),
      itemCount: _sessions.length,
      itemBuilder: (context, index) {
        final session = _sessions[index];
        final sessionId = session['_id'] ?? '';
        final mode = session['mode'] ?? 'flashcard';
        final total = session['total_words'] ?? 0;
        final accuracy = session['accuracy'] ?? 0;
        final xp = session['xp_earned'] ?? 0;
        
        final source = session['source'] ?? 'General';
        final level = session['level'];
        final topic = session['topic'];

        final DateTime completedAt = session['completed_at'] != null
            ? DateTime.tryParse(session['completed_at']) ?? DateTime.now()
            : DateTime.now();

        final dateString = DateFormat('HH:mm - MMM dd, yyyy').format(completedAt);

        // Curated gradients and icons for each learning mode
        late final LinearGradient gradient;
        late final IconData modeIcon;
        late final String modeName;

        switch (mode.toString().toLowerCase()) {
          case 'typing':
            gradient = const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)]);
            modeIcon = Icons.keyboard_alt_rounded;
            modeName = 'Typing Challenge';
            break;
          case 'listening':
            gradient = const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF0891B2)]);
            modeIcon = Icons.volume_up_rounded;
            modeName = 'Listening Lab';
            break;
          case 'reverse_recall':
            gradient = const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4F46E5)]);
            modeIcon = Icons.swap_horizontal_circle_rounded;
            modeName = 'Reverse Recall';
            break;
          case 'fill_blank':
            gradient = const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]);
            modeIcon = Icons.edit_note_rounded;
            modeName = 'Fill Blanks';
            break;
          case 'speech':
            gradient = const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFFBE185D)]);
            modeIcon = Icons.mic_rounded;
            modeName = 'Speech Practice';
            break;
          case 'mixed':
            gradient = const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF047857)]);
            modeIcon = Icons.shuffle_rounded;
            modeName = 'Mixed Challenge';
            break;
          default: // flashcard
            gradient = const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)]);
            modeIcon = Icons.layers_rounded;
            modeName = 'Flashcards';
        }

        return Animate(
          effects: [
            FadeEffect(duration: const Duration(milliseconds: 300)),
            SlideEffect(
              begin: const Offset(0, 0.1),
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutQuad,
            ),
          ],
          delay: Duration(milliseconds: 50 * index),
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            child: AppCard(
              padding: EdgeInsets.zero,
              hasBorder: true,
              onTap: () => _viewSessionDetails(sessionId),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      // Sidebar color strip + icon
                      Container(
                        width: 60,
                        decoration: BoxDecoration(gradient: gradient),
                        child: Center(
                          child: Icon(modeIcon, color: Colors.white, size: 26),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Core details
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                modeName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  _buildBadge(source, Colors.grey.shade100, AppColors.textSecondary),
                                  if (level != null)
                                    _buildBadge(level, AppColors.primary.withOpacity(0.08), AppColors.primary),
                                  if (topic != null)
                                    _buildBadge(topic, AppColors.secondary.withOpacity(0.08), AppColors.secondary),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today_rounded, color: Colors.grey.shade400, size: 12),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      dateString,
                                      style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.menu_book_rounded, color: Colors.grey.shade400, size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$total words',
                                    style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Stats metrics on the right side
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // XP Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.amber.shade200, width: 0.8),
                              ),
                              child: Row(
                                children: [
                                  const Text('⚡', style: TextStyle(fontSize: 10)),
                                  const SizedBox(width: 2),
                                  Text(
                                    '+$xp XP',
                                    style: TextStyle(
                                      color: Colors.amber.shade800,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Accuracy score
                            Row(
                              children: [
                                Text(
                                  '$accuracy%',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    color: accuracy >= 80
                                        ? AppColors.success
                                        : accuracy >= 50
                                            ? Colors.amber.shade700
                                            : AppColors.error,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  'ACC',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBadge(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
