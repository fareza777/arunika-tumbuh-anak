import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class NavItem {
  const NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// Bottom navigation premium: bar putih melengkung, indikator pil emas,
/// dan celah tengah untuk tombol tambah pengukuran.
class PremiumNavBar extends StatelessWidget {
  const PremiumNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    // Indeks visual: slot tengah (index items.length ~/ 2) adalah celah FAB.
    final slotCount = items.length + 1;
    final gapSlot = items.length ~/ 2;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8A7A58).withValues(alpha: 0.14),
            blurRadius: 26,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            children: [
              for (var slot = 0; slot < slotCount; slot++)
                if (slot == gapSlot)
                  const Expanded(child: SizedBox())
                else
                  Expanded(
                    child: _NavButton(
                      item: items[slot < gapSlot ? slot : slot - 1],
                      active:
                          (slot < gapSlot ? slot : slot - 1) == currentIndex,
                      onTap: () => onTap(slot < gapSlot ? slot : slot - 1),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final NavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.goldDeep : AppColors.inkFaint;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            width: active ? 44 : 0,
            height: 4,
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              gradient: active ? AppColors.goldGradient : null,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Icon(active ? item.activeIcon : item.icon, color: color, size: 23),
          const SizedBox(height: 3),
          Text(
            item.label,
            style: AppTheme.sans(
              size: 10.5,
              weight: active ? FontWeight.w800 : FontWeight.w600,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// FAB emas melayang untuk aksi utama (tambah pengukuran).
class GoldFab extends StatelessWidget {
  const GoldFab({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.goldGradient,
        border: Border.all(color: AppColors.ivory, width: 4),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.45),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
        ),
      ),
    );
  }
}
