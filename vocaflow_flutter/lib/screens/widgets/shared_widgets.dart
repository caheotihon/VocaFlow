// Shared reusable widgets for LingoPro
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

// ── Premium Gradient Button ───────────────────────────────────────────────
class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final bool isLoading;
  final double? width;
  final IconData? icon;

  const GradientButton({
    super.key,
    required this.text,
    this.onTap,
    this.isLoading = false,
    this.width,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: width ?? double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(AppRadius.full),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.35),
              blurRadius: 16, offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(text, style: AppTextStyles.button),
                  ],
                ),
        ),
      ),
    );
  }
}

// ── Level Chip ────────────────────────────────────────────────────────────
class LevelChip extends StatelessWidget {
  final String level;
  final bool isSelected;
  final VoidCallback? onTap;

  const LevelChip({
    super.key, required this.level,
    this.isSelected = false, this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.textHint,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8)]
              : [],
        ),
        child: Text(
          level,
          style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── Premium Card ──────────────────────────────────────────────────────────
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final bool hasBorder;

  const AppCard({
    super.key, required this.child,
    this.padding, this.onTap, this.color, this.hasBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color ?? AppColors.cardBg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: hasBorder
              ? Border.all(color: AppColors.primary, width: 2)
              : Border.all(color: Colors.grey.shade100),
          boxShadow: AppColors.cardShadow,
        ),
        child: child,
      ),
    );
  }
}

// ── Progress Bar ─────────────────────────────────────────────────────────
class AppProgressBar extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final Color? color;
  final double height;

  const AppProgressBar({
    super.key, required this.value,
    this.color, this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor: AppColors.background,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? AppColors.primary,
        ),
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key, required this.title,
    this.actionText, this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title.toUpperCase(), style: AppTextStyles.label),
        if (actionText != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionText!,
              style: const TextStyle(
                fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Word Status Badge ──────────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'mastered':  color = AppColors.mastered;  break;
      case 'learning':  color = AppColors.learning;  break;
      case 'reviewing': color = AppColors.reviewing; break;
      default:          color = AppColors.newWord;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ── App Bar ────────────────────────────────────────────────────────────────
class LingoAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showStreak;
  final int streak;
  final Widget? leading;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final PreferredSizeWidget? bottom;
  final bool showBackButton;

  const LingoAppBar({
    super.key,
    this.title,
    this.showStreak = false,
    this.streak = 0,
    this.leading,
    this.actions,
    this.backgroundColor,
    this.bottom,
    this.showBackButton = true,
  });

  @override
  Size get preferredSize => Size.fromHeight(60 + (bottom?.preferredSize.height ?? 0.0));

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);

    return AppBar(
      backgroundColor: backgroundColor ?? AppColors.background,
      elevation: 0,
      automaticallyImplyLeading: showBackButton,
      leading: leading ?? (showBackButton && canPop ? const BackButton(color: AppColors.textPrimary) : null),
      centerTitle: true,
      title: title != null
          ? Text(
              title!,
              style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800,
                foreground: Paint()
                  ..shader = const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ).createShader(const Rect.fromLTWH(0, 0, 150, 20)),
              ),
            )
          : const Text(
              'LingoPro',
              style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
      bottom: bottom,
      actions: [
        if (showStreak) ...[
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text(
                  '${streak}d',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700, color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        ],
        ...?actions,
      ],
    );
  }
}
