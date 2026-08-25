import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_theme.dart';
import '../monetization/stable_banner_ad.dart';
import '../together/garden_screen.dart';
import '../together/moment_editor_screen.dart';
import '../together/moments_screen.dart';
import '../together/ritual_editor_sheet.dart';
import '../together/rituals_screen.dart';
import '../together/today_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  var _index = 0;
  var _showActions = false;

  Future<void> _openMoment() async {
    setState(() => _showActions = false);
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const MomentEditorScreen()));
  }

  Future<void> _openRitual() async {
    setState(() => _showActions = false);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const RitualEditorSheet(),
    );
  }

  void _select(int index) {
    setState(() {
      _index = index;
      _showActions = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MainShellLayout(
        banner: const StableBannerAd(placement: BannerPlacement.mainShell),
        content: IndexedStack(
          index: _index,
          children: [
            TodayScreen(
              onOpenMoment: _openMoment,
              onOpenRitual: _openRitual,
              onOpenGarden: () => _select(3),
            ),
            RitualsScreen(onOpenRitual: _openRitual),
            MomentsScreen(onOpenMoment: _openMoment),
            const GardenScreen(),
          ],
        ),
      ),
      floatingActionButton: _ActionRail(
        expanded: _showActions,
        onToggle: () => setState(() => _showActions = !_showActions),
        onMoment: _openMoment,
        onRitual: _openRitual,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _TogetherNavBar(index: _index, onTap: _select),
    );
  }
}

/// Keeps shell-wide chrome in a predictable order around the active surface.
class MainShellLayout extends StatelessWidget {
  const MainShellLayout({
    super.key,
    required this.banner,
    required this.content,
  });

  final Widget banner;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        banner,
        Expanded(child: content),
      ],
    );
  }
}

class _TogetherNavBar extends StatelessWidget {
  const _TogetherNavBar({required this.index, required this.onTap});

  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: const Border(top: BorderSide(color: AppColors.hairline)),
        boxShadow: AppColors.softShadow(opacity: 0.08, blur: 22, y: -6),
      ),
      padding: EdgeInsets.only(
        left: 10,
        right: 10,
        top: 8,
        bottom: MediaQuery.paddingOf(context).bottom + 8,
      ),
      child: Row(
        children: [
          _NavItem(
            icon: PhosphorIconsLight.sun,
            activeIcon: PhosphorIconsFill.sun,
            label: 'Hari Ini',
            active: index == 0,
            onTap: () => onTap(0),
          ),
          _NavItem(
            icon: PhosphorIconsLight.listChecks,
            activeIcon: PhosphorIconsFill.listChecks,
            label: 'Ritual',
            active: index == 1,
            onTap: () => onTap(1),
          ),
          const SizedBox(width: 78),
          _NavItem(
            icon: PhosphorIconsLight.images,
            activeIcon: PhosphorIconsFill.images,
            label: 'Momen',
            active: index == 2,
            onTap: () => onTap(2),
          ),
          _NavItem(
            icon: PhosphorIconsLight.treeStructure,
            activeIcon: PhosphorIconsFill.treeStructure,
            label: 'Taman',
            active: index == 3,
            onTap: () => onTap(3),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.terracottaDeep : AppColors.inkFaint;
    return Expanded(
      child: Semantics(
        selected: active,
        button: true,
        label: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: AppMotion.duration(
                    context,
                    const Duration(milliseconds: 220),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.terracottaMist
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: PhosphorIcon(
                    active ? activeIcon : icon,
                    size: 21,
                    color: color,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: AppTheme.sans(
                    size: 10,
                    weight: active ? FontWeight.w800 : FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionRail extends StatelessWidget {
  const _ActionRail({
    required this.expanded,
    required this.onToggle,
    required this.onMoment,
    required this.onRitual,
  });

  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onMoment;
  final VoidCallback onRitual;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: AppMotion.duration(
            context,
            const Duration(milliseconds: 220),
          ),
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: expanded
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _QuickAction(
                        icon: PhosphorIconsLight.images,
                        label: 'Catat momen',
                        color: AppColors.terracotta,
                        onTap: onMoment,
                      ),
                      const SizedBox(width: 10),
                      _QuickAction(
                        icon: PhosphorIconsLight.listChecks,
                        label: 'Buat ritual',
                        color: AppColors.sageDeep,
                        onTap: onRitual,
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
        Semantics(
          button: true,
          label: expanded ? 'Tutup aksi cepat' : 'Buka aksi cepat',
          child: GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: AppMotion.duration(
                context,
                const Duration(milliseconds: 280),
              ),
              curve: AppMotion.spring,
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: expanded
                    ? AppColors.terracottaMistGradient
                    : AppColors.sunrise,
                border: Border.all(color: AppColors.paper, width: 5),
                boxShadow: AppColors.softShadow(opacity: 0.18, blur: 24, y: 10),
              ),
              child: Center(
                child: PhosphorIcon(
                  expanded ? PhosphorIconsLight.x : PhosphorIconsLight.plus,
                  size: 27,
                  color: expanded
                      ? AppColors.terracottaDeep
                      : AppColors.espresso,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.paper,
      borderRadius: BorderRadius.circular(18),
      elevation: 3,
      shadowColor: AppColors.ink.withValues(alpha: 0.12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 9),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PhosphorIcon(icon, size: 23, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTheme.sans(
                  size: 9.5,
                  weight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
