// Main Shell — bottom/side navigation controller
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/favorite_provider.dart';
import '../providers/stats_provider.dart';
import '../core/constants/app_constants.dart';
import 'home_screen.dart';
import 'learn_screen.dart';
import 'favorites_screen.dart';
import 'statistics_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    LearnScreen(),
    FavoritesScreen(),
    StatisticsScreen(),
    ProfileScreen(),
  ];

  // Tách data để dễ dàng build cho cả Bottom Nav và Side Nav
  final List<Map<String, dynamic>> _navItems = [
    {'icon': Icons.home_outlined,         'activeIcon': Icons.home_rounded,            'label': 'HOME'},
    {'icon': Icons.school_outlined,        'activeIcon': Icons.school_rounded,           'label': 'LEARN'},
    {'icon': Icons.favorite_border_rounded,'activeIcon': Icons.favorite_rounded,         'label': 'SAVED'},
    {'icon': Icons.bar_chart_outlined,     'activeIcon': Icons.bar_chart_rounded,        'label': 'STATS'},
    {'icon': Icons.person_outline_rounded, 'activeIcon': Icons.person_rounded,           'label': 'PROFILE'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoriteProvider>().loadFavorites();
      context.read<StatsProvider>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;
    final isTablet = width >= 600 && width < 900;
    final isWideScreen = isTablet || isDesktop;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: isWideScreen
          ? Row(
              children: [
                // ── Side Navigation (Tablet & Desktop) ──────────────
                Container(
                  width: isDesktop ? 220 : 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 16, offset: const Offset(4, 0),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        const SizedBox(height: 32),
                        // App Logo nhỏ trên Sidebar (Tùy chọn)
                        Icon(Icons.menu_book_rounded, color: AppColors.primary, size: isDesktop ? 36 : 28),
                        const SizedBox(height: 40),
                        
                        ...List.generate(_navItems.length, (index) {
                          final item = _navItems[index];
                          return Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isDesktop ? 16 : 8,
                              vertical: 8,
                            ),
                            child: _NavItem(
                              icon: item['icon'],
                              activeIcon: item['activeIcon'],
                              label: item['label'],
                              index: index,
                              currentIndex: _currentIndex,
                              isExtended: isDesktop,
                              isSideNav: true,
                              onTap: () => setState(() => _currentIndex = index),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                
                // ── Main Content ────────────────────────────────────
                Expanded(
                  child: IndexedStack(index: _currentIndex, children: _screens),
                ),
              ],
            )
          : IndexedStack(index: _currentIndex, children: _screens), // Mobile Body

      // ── Bottom Navigation (Chỉ hiển thị trên Mobile) ─────────────
      bottomNavigationBar: isWideScreen ? null : Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06),
                blurRadius: 16, offset: const Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_navItems.length, (index) {
                final item = _navItems[index];
                return _NavItem(
                  icon: item['icon'],
                  activeIcon: item['activeIcon'],
                  label: item['label'],
                  index: index,
                  currentIndex: _currentIndex,
                  onTap: () => setState(() => _currentIndex = index),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final int index, currentIndex;
  final VoidCallback onTap;
  
  // Các flag bổ sung để xử lý layout responsive
  final bool isSideNav;
  final bool isExtended;

  const _NavItem({
    required this.icon, required this.activeIcon, required this.label,
    required this.index, required this.currentIndex, required this.onTap,
    this.isSideNav = false, this.isExtended = false,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == currentIndex;
    
    return MouseRegion(
      cursor: SystemMouseCursors.click, // Hiển thị tay chỉ trên Web/Desktop
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: isSideNav
              ? EdgeInsets.symmetric(horizontal: isExtended ? 20 : 0, vertical: 12)
              : const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: isExtended 
              // ── Layout Desktop: Row (Icon trái, Text phải) ──
              ? Row(
                  children: [
                    Icon(
                      isActive ? activeIcon : icon,
                      color: isActive ? AppColors.primary : AppColors.textSecondary,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isActive ? AppColors.primary : AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                )
              // ── Layout Mobile/Tablet: Column (Icon trên, Text dưới) ──
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isActive ? activeIcon : icon,
                      color: isActive ? AppColors.primary : AppColors.textSecondary,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isActive ? AppColors.primary : AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}