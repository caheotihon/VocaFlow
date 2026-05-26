import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import '../models/word_model.dart';
import '../core/constants/app_constants.dart';
import 'widgets/shared_widgets.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ApiService _api = ApiService();
  int _activeTab = 0; // 0 = Analytics, 1 = Users, 2 = Words

  // Analytics State
  Map<String, dynamic>? _stats;
  bool _loadingStats = true;
  String? _statsError;

  // Users State
  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  bool _loadingUsers = true;
  String? _usersError;
  final TextEditingController _userSearchCtrl = TextEditingController();

  // Words State
  List<WordModel> _words = [];
  List<WordModel> _filteredWords = [];
  bool _loadingWords = true;
  String? _wordsError;
  final TextEditingController _wordSearchCtrl = TextEditingController();

  // Global actions loading state
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchStats();
    _fetchUsers();
    _fetchWords();

    _userSearchCtrl.addListener(_filterUsers);
    _wordSearchCtrl.addListener(_filterWords);
  }

  @override
  void dispose() {
    _userSearchCtrl.dispose();
    _wordSearchCtrl.dispose();
    super.dispose();
  }

  // ── Network Operations ──────────────────────────────────────────────────

  Future<void> _fetchStats() async {
    setState(() {
      _loadingStats = true;
      _statsError = null;
    });
    try {
      final res = await _api.getAdminStats();
      if (res.data['success'] == true) {
        setState(() {
          _stats = res.data['data'];
          _loadingStats = false;
        });
      } else {
        setState(() {
          _statsError = res.data['message'] ?? 'Failed to load stats';
          _loadingStats = false;
        });
      }
    } catch (e) {
      setState(() {
        _statsError = 'Network error: Could not fetch stats.';
        _loadingStats = false;
      });
    }
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _loadingUsers = true;
      _usersError = null;
    });
    try {
      final res = await _api.getAdminUsers();
      if (res.data['success'] == true) {
        final List raw = res.data['data']['users'] ?? [];
        setState(() {
          _users = raw.map((u) => UserModel.fromJson(u)).toList();
          _filteredUsers = List.from(_users);
          _loadingUsers = false;
        });
      } else {
        setState(() {
          _usersError = res.data['message'] ?? 'Failed to load users';
          _loadingUsers = false;
        });
      }
    } catch (e) {
      setState(() {
        _usersError = 'Network error: Could not fetch users.';
        _loadingUsers = false;
      });
    }
  }

  Future<void> _fetchWords() async {
    setState(() {
      _loadingWords = true;
      _wordsError = null;
    });
    try {
      // Fetch using the standard limit, or high limit for admin dashboard
      final res = await _api.getWords(page: 1, limit: 250);
      if (res.data['success'] == true) {
        final List raw = res.data['data']['words'] ?? [];
        setState(() {
          _words = raw.map((w) => WordModel.fromJson(w)).toList();
          _filteredWords = List.from(_words);
          _loadingWords = false;
        });
      } else {
        setState(() {
          _wordsError = res.data['message'] ?? 'Failed to load vocabulary';
          _loadingWords = false;
        });
      }
    } catch (e) {
      setState(() {
        _wordsError = 'Network error: Could not fetch vocabulary.';
        _loadingWords = false;
      });
    }
  }

  void _filterUsers() {
    final query = _userSearchCtrl.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = List.from(_users);
      } else {
        _filteredUsers = _users.where((u) {
          return u.name.toLowerCase().contains(query) ||
              u.email.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  void _filterWords() {
    final query = _wordSearchCtrl.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredWords = List.from(_words);
      } else {
        _filteredWords = _words.where((w) {
          return w.word.toLowerCase().contains(query) ||
              w.meaningVn.toLowerCase().contains(query) ||
              w.topic.toLowerCase().contains(query) ||
              w.level.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _toggleUserBlock(UserModel user) async {
    final isCurrentlyBlocked = user.badges.contains('blocked');

    setState(() => _isActionLoading = true);
    try {
      final res = await _api.toggleUserStatus(user.id);
      if (!context.mounted) return;
      if (res.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isCurrentlyBlocked
                ? 'Successfully unblocked ${user.name}'
                : 'Successfully blocked ${user.name}'),
            backgroundColor: AppColors.success,
          ),
        );
        await _fetchUsers();
        await _fetchStats();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.data['message'] ?? 'Action failed'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network error executing user status change.'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isActionLoading = false);
      }
    }
  }

  Future<void> _deleteWord(WordModel word) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Vocabulary?'),
        content: Text('Are you sure you want to permanently delete the word "${word.word}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isActionLoading = true);
    try {
      final res = await _api.adminDeleteWord(word.id);
      if (!context.mounted) return;
      if (res.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted word "${word.word}" successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        await _fetchWords();
        await _fetchStats();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.data['message'] ?? 'Failed to delete word'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error communicating with server to delete word.'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isActionLoading = false);
      }
    }
  }

  // ── Word Creation & Modification Sheet ─────────────────────────────────

  void _showWordForm({WordModel? wordToEdit}) {
    final isEdit = wordToEdit != null;
    final wordCtrl = TextEditingController(text: wordToEdit?.word ?? '');
    final puncCtrl = TextEditingController(text: wordToEdit?.pronunciation ?? '');
    final meaningCtrl = TextEditingController(text: wordToEdit?.meaningVn ?? '');
    final defEnCtrl = TextEditingController(text: wordToEdit?.definitionEn ?? '');
    final defVnCtrl = TextEditingController(text: wordToEdit?.definitionVn ?? '');
    final exEnCtrl = TextEditingController(text: wordToEdit?.example ?? '');
    final exVnCtrl = TextEditingController(text: wordToEdit?.exampleVn ?? '');
    final topicCtrl = TextEditingController(text: wordToEdit?.topic ?? 'General');
    final srcCtrl = TextEditingController(text: wordToEdit?.source ?? 'Cambridge Academic');

    String selectedLevel = wordToEdit?.level ?? 'A1';
    String selectedPOS = wordToEdit?.partOfSpeech ?? 'noun';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppRadius.xl),
              topRight: Radius.circular(AppRadius.xl),
            ),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetCtx).size.height * 0.85,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Grab indicator
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEdit ? 'Edit Vocabulary Word' : 'Add Standard Vocabulary',
                        style: AppTextStyles.h2.copyWith(color: AppColors.primary),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(sheetCtx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Core fields
                  _buildFormTextField('Vocabulary Word', wordCtrl, 'e.g. ephemeral'),
                  const SizedBox(height: 12),
                  _buildFormTextField('Pronunciation', puncCtrl, 'e.g. /ɪˈfem.ər.əl/'),
                  const SizedBox(height: 12),
                  _buildFormTextField('Vietnamese Meaning', meaningCtrl, 'e.g. phù du, chóng tàn'),
                  const SizedBox(height: 16),

                  // Level and Part Of Speech Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('CEFR Level', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedLevel,
                                  isExpanded: true,
                                  items: ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']
                                      .map((lvl) => DropdownMenuItem(value: lvl, child: Text(lvl)))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) setSheetState(() => selectedLevel = val);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Part Of Speech', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedPOS,
                                  isExpanded: true,
                                  items: ['noun', 'verb', 'adjective', 'adverb', 'preposition', 'conjunction']
                                      .map((pos) => DropdownMenuItem(value: pos, child: Text(pos[0].toUpperCase() + pos.substring(1))))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) setSheetState(() => selectedPOS = val);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildFormTextField('English Definition', defEnCtrl, 'A concise explanation in English', maxLines: 2),
                  const SizedBox(height: 12),
                  _buildFormTextField('Vietnamese Definition', defVnCtrl, 'Giải thích nghĩa chi tiết bằng tiếng Việt', maxLines: 2),
                  const SizedBox(height: 12),
                  _buildFormTextField('Example Sentence', exEnCtrl, 'An illustrative English sentence.', maxLines: 2),
                  const SizedBox(height: 12),
                  _buildFormTextField('Example Vietnamese Translation', exVnCtrl, 'Bản dịch tiếng Việt của câu ví dụ.', maxLines: 2),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(child: _buildFormTextField('Topic Category', topicCtrl, 'e.g. Science, Nature')),
                      const SizedBox(width: 16),
                      Expanded(child: _buildFormTextField('Vocabulary Source', srcCtrl, 'e.g. Oxford 3000')),
                    ],
                  ),
                  const SizedBox(height: 32),

                  GradientButton(
                    text: isEdit ? 'Update Word Details' : 'Create New Vocabulary',
                    onTap: () async {
                      if (wordCtrl.text.isEmpty || meaningCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(sheetCtx).showSnackBar(
                          const SnackBar(content: Text('Please fill Word and Vietnamese Meaning'), backgroundColor: AppColors.error),
                        );
                        return;
                      }

                      final data = {
                        'word': wordCtrl.text.trim(),
                        'pronunciation': puncCtrl.text.trim(),
                        'meaning_vn': meaningCtrl.text.trim(),
                        'definition_en': defEnCtrl.text.trim(),
                        'definition_vn': defVnCtrl.text.trim(),
                        'example': exEnCtrl.text.trim(),
                        'example_vn': exVnCtrl.text.trim(),
                        'level': selectedLevel,
                        'partOfSpeech': selectedPOS,
                        'topic': topicCtrl.text.trim(),
                        'source': srcCtrl.text.trim(),
                      };

                      Navigator.pop(ctx);
                      setState(() => _isActionLoading = true);

                      try {
                        final res = isEdit
                            ? await _api.adminUpdateWord(wordToEdit.id, data)
                            : await _api.adminCreateWord(data);

                        if (!context.mounted) return;
                        if (res.data['success'] == true) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isEdit ? 'Word updated successfully' : 'Word created successfully'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                          _fetchWords();
                          _fetchStats();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(res.data['message'] ?? 'Action failed'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Network error executing vocabulary save.'), backgroundColor: AppColors.error),
                        );
                      } finally {
                        if (mounted) {
                          setState(() => _isActionLoading = false);
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormTextField(String label, TextEditingController ctrl, String hint, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            filled: true,
            fillColor: Colors.grey.shade50,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // ── Layout Views ────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final auth = context.watch<AuthProvider>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ADMIN CONTROL PANEL',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'LingoPro Platform Management',
              style: AppTextStyles.h1.copyWith(letterSpacing: -0.5),
            ),
          ],
        ),
        Row(
          children: [
            // Safe Admin indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.admin_panel_settings_rounded, color: AppColors.primary, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    auth.user?.name ?? 'Admin Account',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: AppColors.error),
              tooltip: 'Sign Out',
              onPressed: () async {
                await auth.logout();
                if (!context.mounted) return;
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsView() {
    if (_loadingStats) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(40),
        child: CircularProgressIndicator(),
      ));
    }

    if (_statsError != null) {
      return _buildErrorPlaceholder(_statsError!, _fetchStats);
    }

    final stats = _stats!;
    final totalUsers = stats['totalUsers'] ?? 0;
    final activeToday = stats['activeUsersToday'] ?? 0;
    final totalWords = stats['totalWords'] ?? 0;
    final totalStories = stats['totalStories'] ?? 0;
    final averageXp = stats['averageXp'] ?? 0.0;
    final cefrDist = stats['cefrDistribution'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stat cards grid
          LayoutBuilder(
            builder: (ctx, constraints) {
              final isWide = constraints.maxWidth > 700;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: isWide ? 4 : 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: isWide ? 1.6 : 1.3,
                children: [
                  _buildStatCard(
                    'Total Learners',
                    totalUsers.toString(),
                    Icons.people_alt_rounded,
                    [const Color(0xFF4F46E5), const Color(0xFF7C3AED)],
                  ),
                  _buildStatCard(
                    'Active Today',
                    activeToday.toString(),
                    Icons.offline_bolt_rounded,
                    [const Color(0xFF10B981), const Color(0xFF059669)],
                  ),
                  _buildStatCard(
                    'Total Vocabulary',
                    totalWords.toString(),
                    Icons.library_books_rounded,
                    [const Color(0xFF06B6D4), const Color(0xFF0891B2)],
                  ),
                  _buildStatCard(
                    'AI Stories Generated',
                    totalStories.toString(),
                    Icons.auto_stories_rounded,
                    [const Color(0xFFF59E0B), const Color(0xFFD97706)],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Secondary row (Average XP & distributions)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'CEFR Level Word Distribution',
                            style: AppTextStyles.h3,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppRadius.full),
                            ),
                            child: const Text('Cambridge standard', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (cefrDist.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Center(child: Text('No CEFR distribution data available.', style: TextStyle(color: AppColors.textSecondary))),
                        )
                      else
                        Column(
                          children: cefrDist.entries.map((entry) {
                            final level = entry.key;
                            final count = entry.value as int;
                            final total = cefrDist.values.fold<int>(0, (prev, element) => prev + (element as int));
                            final percentage = total > 0 ? count / total : 0.0;

                            // Premium CEFR colors
                            Color levelColor;
                            switch (level.toUpperCase()) {
                              case 'A1': levelColor = const Color(0xFF10B981); break;
                              case 'A2': levelColor = const Color(0xFF06B6D4); break;
                              case 'B1': levelColor = const Color(0xFF3B82F6); break;
                              case 'B2': levelColor = const Color(0xFF8B5CF6); break;
                              case 'C1': levelColor = const Color(0xFF6366F1); break;
                              case 'C2': levelColor = const Color(0xFFEC4899); break;
                              default: levelColor = AppColors.primary;
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14.0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 38,
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    decoration: BoxDecoration(
                                      color: levelColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Center(
                                      child: Text(
                                        level,
                                        style: TextStyle(fontWeight: FontWeight.bold, color: levelColor, fontSize: 13),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(AppRadius.full),
                                      child: LinearProgressIndicator(
                                        value: percentage,
                                        minHeight: 10,
                                        backgroundColor: Colors.grey.shade100,
                                        valueColor: AlwaysStoppedAnimation<Color>(levelColor),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  SizedBox(
                                    width: 60,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          '$count',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        Text(
                                          ' (${(percentage * 100).toStringAsFixed(0)}%)',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.military_tech_rounded, size: 48, color: Color(0xFFF59E0B)),
                      const SizedBox(height: 12),
                      const Text(
                        'Learner Engagement',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${averageXp.toStringAsFixed(1)} XP',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Average XP accumulated per user',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Divider(color: Colors.grey.shade100),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildEngagementColumn('Standard Users', (totalUsers - activeToday).clamp(0, 99999).toString()),
                          _buildEngagementColumn('Daily Retention', '${totalUsers > 0 ? ((activeToday / totalUsers) * 100).toStringAsFixed(0) : 0}%'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementColumn(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildUsersView() {
    if (_loadingUsers) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(40),
        child: CircularProgressIndicator(),
      ));
    }

    if (_usersError != null) {
      return _buildErrorPlaceholder(_usersError!, _fetchUsers);
    }

    final isWide = MediaQuery.of(context).size.width >= 900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search bar
        TextField(
          controller: _userSearchCtrl,
          decoration: InputDecoration(
            hintText: 'Search learners by name or email address...',
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
            fillColor: Colors.white,
            filled: true,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: BorderSide(color: Colors.grey.shade100),
            ),
          ),
        ),
        const SizedBox(height: 16),

        Expanded(
          child: AppCard(
            padding: EdgeInsets.zero,
            child: _filteredUsers.isEmpty
                ? const Center(child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('No learners match your search query.', style: TextStyle(color: AppColors.textSecondary)),
                  ))
                : isWide
                    ? SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: DataTable(
                            columnSpacing: 28,
                            columns: const [
                              DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Email Address', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Joined Date', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Total XP', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Streak', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Account Status', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                            rows: _filteredUsers.map((user) {
                              final isBlocked = user.badges.contains('blocked');
                              final joinStr = user.createdAt != null
                                  ? DateFormat('MMM dd, yyyy').format(user.createdAt!)
                                  : 'Unknown';

                              return DataRow(
                                cells: [
                                  DataCell(
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 14,
                                          backgroundColor: AppColors.primary.withOpacity(0.1),
                                          backgroundImage: user.avatar != null ? NetworkImage(user.avatar!) : null,
                                          child: user.avatar == null
                                              ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary))
                                              : null,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                        if (user.role == 'admin') ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: Colors.red.shade50,
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: Colors.red.shade100),
                                            ),
                                            child: const Text('Admin', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.red)),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  DataCell(Text(user.email)),
                                  DataCell(Text(joinStr)),
                                  DataCell(Text('${user.totalXP} XP', style: const TextStyle(fontWeight: FontWeight.bold))),
                                  DataCell(Text('🔥 ${user.streakDays}d')),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isBlocked ? Colors.red.shade50 : Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(AppRadius.full),
                                      ),
                                      child: Text(
                                        isBlocked ? 'Blocked' : 'Active',
                                        style: TextStyle(
                                          color: isBlocked ? Colors.red : Colors.green,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    user.role == 'admin'
                                        ? const Text('-', style: TextStyle(color: AppColors.textSecondary))
                                        : TextButton(
                                            onPressed: () => _toggleUserBlock(user),
                                            style: TextButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                              minimumSize: const Size(60, 30),
                                            ),
                                            child: Text(
                                              isBlocked ? 'Unblock' : 'Block',
                                              style: TextStyle(
                                                color: isBlocked ? Colors.green : Colors.red,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _filteredUsers.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        itemBuilder: (ctx, i) {
                          final user = _filteredUsers[i];
                          final isBlocked = user.badges.contains('blocked');
                          final joinStr = user.createdAt != null
                              ? DateFormat('MMM dd').format(user.createdAt!)
                              : '-';

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withOpacity(0.1),
                              backgroundImage: user.avatar != null ? NetworkImage(user.avatar!) : null,
                              child: user.avatar == null
                                  ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary))
                                  : null,
                            ),
                            title: Row(
                              children: [
                                Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                if (user.role == 'admin') ...[
                                  const SizedBox(width: 6),
                                  const Icon(Icons.star_rounded, color: Colors.orange, size: 14),
                                ],
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 2),
                                Text(user.email, style: const TextStyle(fontSize: 12)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text('🔥 ${user.streakDays}d', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 8),
                                    Text('•  ${user.totalXP} XP', style: const TextStyle(fontSize: 11)),
                                    const SizedBox(width: 8),
                                    Text('•  Joined $joinStr', style: const TextStyle(fontSize: 11)),
                                  ],
                                ),
                              ],
                            ),
                            trailing: user.role == 'admin'
                                ? null
                                : Switch(
                                    value: !isBlocked,
                                    activeThumbColor: Colors.green,
                                    inactiveThumbColor: Colors.red,
                                    inactiveTrackColor: Colors.red.shade100,
                                    onChanged: (_) => _toggleUserBlock(user),
                                  ),
                          );
                        },
                      ),
          ),
        ),
      ],
    );
  }

  Widget _buildWordsView() {
    if (_loadingWords) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(40),
        child: CircularProgressIndicator(),
      ));
    }

    if (_wordsError != null) {
      return _buildErrorPlaceholder(_wordsError!, _fetchWords);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Controls: Search & "Add word" button
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _wordSearchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search vocabulary word, meaning or level...',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                  fillColor: Colors.white,
                  filled: true,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: BorderSide(color: Colors.grey.shade100),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => _showWordForm(),
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add_rounded, color: Colors.white),
                    SizedBox(width: 6),
                    Text('Add Word', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Expanded(
          child: AppCard(
            padding: EdgeInsets.zero,
            child: _filteredWords.isEmpty
                ? const Center(child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('No vocabulary matches your search.', style: TextStyle(color: AppColors.textSecondary)),
                  ))
                : ListView.separated(
                    itemCount: _filteredWords.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    itemBuilder: (ctx, i) {
                      final word = _filteredWords[i];

                      // Distinct level coloring
                      Color levelColor;
                      switch (word.level.toUpperCase()) {
                        case 'A1': levelColor = const Color(0xFF10B981); break;
                        case 'A2': levelColor = const Color(0xFF06B6D4); break;
                        case 'B1': levelColor = const Color(0xFF3B82F6); break;
                        case 'B2': levelColor = const Color(0xFF8B5CF6); break;
                        case 'C1': levelColor = const Color(0xFF6366F1); break;
                        case 'C2': levelColor = const Color(0xFFEC4899); break;
                        default: levelColor = AppColors.primary;
                      }

                      return ListTile(
                        leading: Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(
                            color: levelColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              word.level,
                              style: TextStyle(fontWeight: FontWeight.bold, color: levelColor, fontSize: 13),
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              word.word,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              word.pronunciation,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                word.partOfSpeech.toUpperCase(),
                                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              word.meaningVn,
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            if (word.example.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Ex: ${word.example}',
                                style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12, color: AppColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                _buildWordMetaChip('📚  ${word.source}'),
                                _buildWordMetaChip('🏷️  ${word.topic}'),
                              ],
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                              onPressed: () => _showWordForm(wordToEdit: word),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                              onPressed: () => _deleteWord(word),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildWordMetaChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, List<Color> colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 12),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorPlaceholder(String error, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
            const SizedBox(height: 12),
            Text(error, style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry Connection'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Main UI Assembly ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 900;

    Widget bodyContent;
    switch (_activeTab) {
      case 0:  bodyContent = _buildStatsView(); break;
      case 1:  bodyContent = _buildUsersView(); break;
      case 2:  bodyContent = _buildWordsView(); break;
      default: bodyContent = const Center(child: Text('Invalid View'));
    }

    if (isWide) {
      // Stunning Desktop/Web Layout with Sidebar
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            Row(
              children: [
                // Glassmorphic Left Sidebar Navigation
                Container(
                  width: 250,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(right: BorderSide(color: Colors.grey.shade100)),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      // Brand Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 38, height: 38,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'LingoPro',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'ADMIN PANEL',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.textSecondary, letterSpacing: 2),
                      ),
                      const SizedBox(height: 48),

                      // Navigation menu options
                      _buildSidebarItem(0, 'Dashboard Stats', Icons.analytics_outlined),
                      const SizedBox(height: 6),
                      _buildSidebarItem(1, 'Manage Learners', Icons.people_outline_rounded),
                      const SizedBox(height: 6),
                      _buildSidebarItem(2, 'Standard Vocab', Icons.my_library_books_outlined),
                    ],
                  ),
                ),

                // Main Admin Panel
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 32),
                        Expanded(child: bodyContent),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_isActionLoading)
              Container(
                color: Colors.black26,
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      );
    } else {
      // Responsive Mobile/Tablet Layout
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            _activeTab == 0 ? 'Dashboard Stats' : _activeTab == 1 ? 'Manage Learners' : 'Standard Vocab',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: AppColors.error),
              onPressed: () async {
                final auth = context.read<AuthProvider>();
                await auth.logout();
                if (!context.mounted) return;
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: bodyContent,
            ),
            if (_isActionLoading)
              Container(
                color: Colors.black26,
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _activeTab,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          onTap: (i) => setState(() => _activeTab = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.analytics_rounded), label: 'Stats'),
            BottomNavigationBarItem(icon: Icon(Icons.people_rounded), label: 'Learners'),
            BottomNavigationBarItem(icon: Icon(Icons.my_library_books_rounded), label: 'Vocab'),
          ],
        ),
      );
    }
  }

  Widget _buildSidebarItem(int index, String label, IconData icon) {
    final isSelected = _activeTab == index;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
