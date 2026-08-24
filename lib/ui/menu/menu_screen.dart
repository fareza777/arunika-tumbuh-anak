import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/fade_slide.dart';
import '../../core/widgets/gender_avatar.dart';
import '../../core/widgets/luxe_card.dart';
import '../../core/widgets/section_header.dart';
import '../../state/providers.dart';
import '../children/children_screen.dart';
import '../immunization/immunization_screen.dart';
import '../insights/insights_screen.dart';
import '../milestones/milestones_screen.dart';
import '../nutrition/nutrition_screen.dart';
import '../report/report_screen.dart';
import '../settings/settings_screen.dart';

/// Menu utama: akses ke seluruh fitur sekunder aplikasi.
class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(selectedChildProvider);

    final items = [
      _MenuItem(
        icon: Icons.family_restroom_rounded,
        title: 'Profil Anak',
        subtitle: 'Kelola data & foto anak',
        color: AppColors.gold,
        builder: (_) => const ChildrenScreen(),
      ),
      _MenuItem(
        icon: Icons.favorite_rounded,
        title: 'Insight & Prediksi',
        subtitle: 'Velocity & tinggi dewasa',
        color: AppColors.girl,
        builder: (_) => const InsightsScreen(),
      ),
      _MenuItem(
        icon: Icons.emoji_flags_rounded,
        title: 'Milestone',
        subtitle: 'Checklist perkembangan',
        color: AppColors.boy,
        builder: (_) => const MilestonesScreen(),
      ),
      _MenuItem(
        icon: Icons.vaccines_rounded,
        title: 'Imunisasi',
        subtitle: 'Jadwal nasional & IDAI',
        color: AppColors.good,
        builder: (_) => const ImmunizationScreen(),
      ),
      _MenuItem(
        icon: Icons.restaurant_menu_rounded,
        title: 'Gizi Harian',
        subtitle: 'Acuan AKG & checklist',
        color: const Color(0xFF7BA05B),
        builder: (_) => const NutritionScreen(),
      ),
      _MenuItem(
        icon: Icons.picture_as_pdf_rounded,
        title: 'Laporan PDF',
        subtitle: 'Ekspor untuk dokter',
        color: AppColors.danger,
        builder: (_) => const ReportScreen(),
      ),
      _MenuItem(
        icon: Icons.settings_rounded,
        title: 'Pengaturan',
        subtitle: 'Standar & pengingat',
        color: AppColors.info,
        builder: (_) => const SettingsScreen(),
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
          children: [
            Text(
              'Menu',
              style: AppTheme.serif(size: 26, weight: FontWeight.w600),
            ),
            const SizedBox(height: 18),
            if (child != null)
              FadeSlideIn(
                child: LuxeCard(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFFFFF), Color(0xFFFBF4E2)],
                  ),
                  borderColor: AppColors.goldSoft,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ChildrenScreen()),
                  ),
                  child: Row(
                    children: [
                      GenderAvatar(
                        name: child.name,
                        isBoy: child.isBoy,
                        photoPath: child.photoPath,
                        size: 54,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              child.name,
                              style: AppTheme.serif(
                                size: 18,
                                weight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${child.ageLabel} • ${child.gender.label}',
                              style: AppTheme.sans(
                                size: 12,
                                color: AppColors.inkSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.swap_horiz_rounded,
                        color: AppColors.goldDeep,
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 22),
            const SectionHeader(title: 'Semua Fitur'),
            StaggeredColumn(
              children: [
                for (var i = 0; i < items.length; i += 2)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      children: [
                        Expanded(child: _MenuCard(item: items[i])),
                        const SizedBox(width: 14),
                        Expanded(
                          child: i + 1 < items.length
                              ? _MenuCard(item: items[i + 1])
                              : const SizedBox(),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: Column(
                children: [
                  Text(
                    AppIdentity.fullName,
                    style: AppTheme.sans(
                      size: 12,
                      weight: FontWeight.w700,
                      color: AppColors.inkFaint,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Versi ${AppIdentity.version} • Data tersimpan privat di perangkat',
                    style: AppTheme.sans(size: 10.5, color: AppColors.inkFaint),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.builder,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final WidgetBuilder builder;
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.item});

  final _MenuItem item;

  @override
  Widget build(BuildContext context) {
    return LuxeCard(
      onTap: () =>
          Navigator.of(context).push(MaterialPageRoute(builder: item.builder)),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconTile(icon: item.icon, color: item.color),
          const SizedBox(height: 14),
          Text(
            item.title,
            style: AppTheme.sans(size: 14.5, weight: FontWeight.w800),
          ),
          const SizedBox(height: 3),
          Text(
            item.subtitle,
            style: AppTheme.sans(
              size: 11,
              weight: FontWeight.w600,
              color: AppColors.inkFaint,
            ),
          ),
        ],
      ),
    );
  }
}
