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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 20),
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
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isActive ? activeBg : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    item.icon,
                    size: 18,
                    color: isActive ? activeColor : AppColors.ink400,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? activeColor : AppColors.ink400,
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
