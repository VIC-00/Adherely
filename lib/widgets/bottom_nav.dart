import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum NavTab { home, history, health, profile }

class _NavItem {
  final NavTab id;
  final String label;
  final IconData icon;
  const _NavItem(this.id, this.label, this.icon);
}

const List<_NavItem> _navItems = [
  _NavItem(NavTab.home, 'Home', Icons.home_rounded),
  _NavItem(NavTab.history, 'History', Icons.calendar_month_rounded),
  _NavItem(NavTab.health, 'Health', Icons.favorite_rounded),
  _NavItem(NavTab.profile, 'Profile', Icons.person_rounded),
];

/// A floating pill-shaped navigation bar that sits above all screen content.
/// Drop this into a Stack as the last child, aligned to the bottom.
class FloatingBottomNav extends StatelessWidget {
  final NavTab active;
  final ValueChanged<NavTab>? onTap;

  const FloatingBottomNav({super.key, required this.active, this.onTap});

  @override
  Widget build(BuildContext context) {
    AppColors.isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Positioned(
      left: 20,
      right: 20,
      bottom: (bottomPad > 0 ? bottomPad : 12) + 4,
      child: _FloatingBar(active: active, onTap: onTap),
    );
  }
}

class _FloatingBar extends StatelessWidget {
  final NavTab active;
  final ValueChanged<NavTab>? onTap;
  const _FloatingBar({required this.active, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.isDark
            ? const Color(0xFF1E2432)
            : Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: AppColors.isDark ? 0.40 : 0.12),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: AppColors.isDark ? 0.10 : 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: AppColors.isDark
              ? const Color(0xFF2D3448)
              : const Color(0xFFF1F5F9),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _navItems.map((item) => _NavButton(
          item: item,
          isActive: item.id == active,
          onTap: () => onTap?.call(item.id),
        )).toList(),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.isDark
        ? const Color(0xFF60A5FA)
        : const Color(0xFF2563EB);
    final inactiveColor = AppColors.isDark
        ? const Color(0xFF6B7280)
        : const Color(0xFF9CA3AF);
    final activeBg = AppColors.isDark
        ? const Color(0xFF1E3A8A)
        : const Color(0xFFEFF6FF);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 16 : 14,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isActive ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: isActive
            // Active: icon + label side by side (pill expands)
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.icon, size: 20, color: activeColor),
                  const SizedBox(width: 6),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: activeColor,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              )
            // Inactive: icon only
            : Icon(item.icon, size: 22, color: inactiveColor),
      ),
    );
  }
}
