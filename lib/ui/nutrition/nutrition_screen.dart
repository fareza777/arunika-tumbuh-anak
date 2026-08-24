import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/luxe_card.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/stat_ring.dart';
import '../../domain/content/nutrition_data.dart';
import '../../state/providers.dart';

/// Panduan Gizi Harian: acuan AKG resmi per kelompok usia + checklist harian.
///
/// Angka yang ditampilkan adalah acuan umum dari Permenkes RI No. 28/2019
/// dan panduan MP-ASI WHO/Kemenkes — bukan resep individu.
class NutritionScreen extends ConsumerWidget {
  const NutritionScreen({super.key});

  IconData _iconFor(String key) => switch (key) {
    'mother' => Icons.child_care_rounded,
    'sun' => Icons.wb_sunny_rounded,
    'meal' => Icons.restaurant_rounded,
    'snack' => Icons.cookie_rounded,
    'protein' => Icons.egg_alt_rounded,
    'veggie' => Icons.eco_rounded,
    'water' => Icons.water_drop_rounded,
    _ => Icons.check_circle_outline_rounded,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(selectedChildProvider);
    final checkedAsync = ref.watch(nutritionTodayProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Panduan Gizi Harian')),
      body: child == null
          ? const EmptyState(
              icon: Icons.restaurant_menu_rounded,
              title: 'Belum Ada Anak Terpilih',
              message:
                  'Tambahkan profil anak untuk melihat panduan gizi sesuai usianya.',
            )
          : Builder(
              builder: (context) {
                final guide = nutritionGuideFor(child.effectiveAgeInMonths);
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                  children: [
                    // ── Kartu AKG ────────────────────────────────────────
                    LuxeCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: AppColors.goldGradient,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(24),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'KEBUTUHAN ENERGI • ${guide.ageLabel.toUpperCase()}',
                                        style: AppTheme.sans(
                                          size: 10,
                                          weight: FontWeight.w800,
                                          color: Colors.white.withValues(
                                            alpha: 0.85,
                                          ),
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${guide.energyKkal} kkal/hari',
                                        style: AppTheme.serif(
                                          size: 28,
                                          weight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.restaurant_menu_rounded,
                                  size: 40,
                                  color: Colors.white70,
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(18),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _MacroStat(
                                  label: 'Protein',
                                  value: '${guide.proteinG} g',
                                ),
                                _MacroStat(
                                  label: 'Lemak',
                                  value: '${guide.fatG} g',
                                ),
                                _MacroStat(
                                  label: 'Karbo',
                                  value: '${guide.carbsG} g',
                                ),
                                _MacroStat(
                                  label: 'Air',
                                  value: '${guide.waterMl} ml',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Acuan: Angka Kecukupan Gizi (AKG) — Permenkes RI No. 28 Tahun 2019.',
                      style: AppTheme.sans(
                        size: 10.5,
                        color: AppColors.inkFaint,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Panduan pemberian makan ──────────────────────────
                    const SectionHeader(title: 'Panduan Pemberian Makan'),
                    LuxeCard(
                      child: Column(
                        children: [
                          _GuideRow(
                            icon: Icons.schedule_rounded,
                            title: 'Frekuensi',
                            body: guide.frequency,
                          ),
                          const Divider(height: 22),
                          _GuideRow(
                            icon: Icons.soup_kitchen_rounded,
                            title: 'Porsi',
                            body: guide.portion,
                          ),
                          const Divider(height: 22),
                          _GuideRow(
                            icon: Icons.blur_on_rounded,
                            title: 'Tekstur',
                            body: guide.texture,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Checklist harian ─────────────────────────────────
                    SectionHeader(
                      title:
                          'Checklist Hari Ini — ${child.name.split(' ').first}',
                    ),
                    LuxeCard(
                      child: checkedAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (e, _) => Text('Gagal memuat: $e'),
                        data: (checked) {
                          final done = guide.checklist
                              .where((c) => checked.contains(c.id))
                              .length;
                          return Column(
                            children: [
                              Row(
                                children: [
                                  StatRing(
                                    progress: guide.checklist.isEmpty
                                        ? 0
                                        : done / guide.checklist.length,
                                    size: 64,
                                    strokeWidth: 7,
                                    center: Text(
                                      '$done/${guide.checklist.length}',
                                      style: AppTheme.serif(
                                        size: 14,
                                        weight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      done == guide.checklist.length
                                          ? 'Lengkap! Pola makan hari ini sudah sesuai panduan.'
                                          : 'Centang setiap kebiasaan baik yang sudah dilakukan hari ini.',
                                      style: AppTheme.sans(
                                        size: 12,
                                        color: AppColors.inkSoft,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              for (final item in guide.checklist)
                                _ChecklistTile(
                                  item: item,
                                  icon: _iconFor(item.icon),
                                  checked: checked.contains(item.id),
                                  onToggle: (value) {
                                    HapticFeedback.selectionClick();
                                    ref
                                        .read(nutritionActionsProvider)
                                        .toggle(child.id, item.id, value);
                                  },
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Pesan kunci ──────────────────────────────────────
                    const SectionHeader(title: 'Pesan Kunci Gizi Seimbang'),
                    LuxeCard(
                      child: Column(
                        children: [
                          for (
                            var i = 0;
                            i < kNutritionKeyMessages.length;
                            i++
                          ) ...[
                            if (i > 0) const Divider(height: 20),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppColors.goldMist,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.goldSoft,
                                    ),
                                  ),
                                  child: Text(
                                    '${i + 1}',
                                    style: AppTheme.sans(
                                      size: 11,
                                      weight: FontWeight.w800,
                                      color: AppColors.goldDeep,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    kNutritionKeyMessages[i],
                                    style: AppTheme.sans(
                                      size: 12,
                                      color: AppColors.inkSoft,
                                      height: 1.55,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Disclaimer ───────────────────────────────────────
                    SoftCard(
                      color: AppColors.infoSoft,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                            color: AppColors.info,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Angka di atas adalah acuan umum untuk anak sehat per kelompok usia, '
                              'bukan target wajib harian. Kebutuhan setiap anak berbeda tergantung '
                              'aktivitas dan kondisi kesehatan. Bila berat badan anak kurang atau '
                              'berlebih, konsultasikan pola makannya ke ahli gizi/dokter.',
                              style: AppTheme.sans(
                                size: 11,
                                color: AppColors.inkSoft,
                                height: 1.55,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _MacroStat extends StatelessWidget {
  const _MacroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTheme.serif(
            size: 17,
            weight: FontWeight.w600,
            color: AppColors.goldDeep,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label.toUpperCase(),
          style: AppTheme.sans(
            size: 9.5,
            weight: FontWeight.w800,
            color: AppColors.inkFaint,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class _GuideRow extends StatelessWidget {
  const _GuideRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconTile(icon: icon, color: AppColors.gold, size: 40, iconSize: 19),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.sans(size: 12.5, weight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(
                body,
                style: AppTheme.sans(
                  size: 12,
                  color: AppColors.inkSoft,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChecklistTile extends StatelessWidget {
  const _ChecklistTile({
    required this.item,
    required this.icon,
    required this.checked,
    required this.onToggle,
  });

  final ChecklistItem item;
  final IconData icon;
  final bool checked;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => onToggle(!checked),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: checked ? AppColors.goldGradient : null,
                color: checked ? null : AppColors.pearl,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: checked ? Colors.transparent : AppColors.hairline,
                  width: 1.6,
                ),
              ),
              child: checked
                  ? const Icon(
                      Icons.check_rounded,
                      size: 17,
                      color: Colors.white,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 11),
          Icon(
            icon,
            size: 17,
            color: checked ? AppColors.goldDeep : AppColors.inkFaint,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.label,
              style: AppTheme.sans(
                size: 12.5,
                weight: FontWeight.w700,
                color: checked ? AppColors.inkSoft : AppColors.ink,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
