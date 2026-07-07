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

class BottomNav extends StatelessWidget {
  final NavTab active;
  final ValueChanged<NavTab>? onTap;

  const BottomNav({super.key, required this.active, this.onTap});

  @override
  Widget build(BuildContext context) {
    AppColors.isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: AppColors.isDark ? 0.15 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(top: BorderSide(color: AppColors.hairline)),
      ),
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _navItems.map((item) {
          final isActive = item.id == active;
          final activeColor = AppColors.isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
          final activeBg = AppColors.isDark ? const Color(0xFF1E3A8A) : AppColors.medBlueLight;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onTap?.call(item.id),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isActive ? activeBg : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    item.icon,
                    size: 20,
                    color: isActive ? activeColor : AppColors.ink400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? activeColor : AppColors.ink500,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
