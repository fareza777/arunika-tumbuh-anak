import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/luxe_card.dart';
import '../../core/widgets/stat_ring.dart';
import '../../domain/content/milestone_data.dart';
import '../../state/providers.dart';

/// Checklist milestone perkembangan sesuai usia anak.
class MilestonesScreen extends ConsumerStatefulWidget {
  const MilestonesScreen({super.key});

  @override
  ConsumerState<MilestonesScreen> createState() => _MilestonesScreenState();
}

class _MilestonesScreenState extends ConsumerState<MilestonesScreen> {
  MilestoneCategory? _filter;

  @override
  Widget build(BuildContext context) {
    final child = ref.watch(selectedChildProvider);
    final statusAsync = ref.watch(milestoneStatusProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Milestone Perkembangan')),
      body: child == null
          ? const EmptyState(
              icon: Icons.emoji_flags_rounded,
              title: 'Belum Ada Anak Terpilih',
              message:
                  'Tambahkan profil anak untuk memantau milestone perkembangannya.',
            )
          : statusAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Terjadi kesalahan: $e')),
              data: (status) {
                // Milestone memakai usia terkoreksi untuk bayi prematur (AAP).
                final ageMonths = child.effectiveAgeInMonths;
                final achieved = status.keys.toSet();

                final visible =
                    kMilestones
                        .where((m) => _filter == null || m.category == _filter)
                        .toList()
                      ..sort(
                        (a, b) => a.typicalMonths.compareTo(b.typicalMonths),
                      );

                final totalRelevant = kMilestones
                    .where((m) => m.windowEndMonths <= ageMonths + 6)
                    .length;
                final achievedRelevant = kMilestones
                    .where(
                      (m) =>
                          m.windowEndMonths <= ageMonths + 6 &&
                          achieved.contains(m.id),
                    )
                    .length;

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                  children: [
                    // ── Ringkasan progres ────────────────────────────────
                    LuxeCard(
                      child: Row(
                        children: [
                          StatRing(
                            progress: totalRelevant == 0
                                ? 0
                                : achievedRelevant / totalRelevant,
                            size: 92,
                            center: Text(
                              '$achievedRelevant/$totalRelevant',
                              style: AppTheme.serif(
                                size: 18,
                                weight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Progres ${child.name.split(' ').first}',
                                  style: AppTheme.serif(
                                    size: 17.5,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Milestone yang sudah tercapai dari yang relevan untuk usia ${child.ageLabel}.',
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
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Filter kategori ──────────────────────────────────
                    SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _FilterChip(
                            label: 'Semua',
                            selected: _filter == null,
                            onTap: () => setState(() => _filter = null),
                          ),
                          for (final cat in MilestoneCategory.values) ...[
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: cat.label,
                              selected: _filter == cat,
                              onTap: () => setState(() => _filter = cat),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Daftar milestone ─────────────────────────────────
                    for (final milestone in visible)
                      _MilestoneTile(
                        milestone: milestone,
                        achieved: achieved.contains(milestone.id),
                        achievedDate: status[milestone.id],
                        childAgeMonths: ageMonths,
                        onToggle: (value) {
                          HapticFeedback.selectionClick();
                          ref
                              .read(progressActionsProvider)
                              .toggleMilestone(child.id, milestone.id, value);
                        },
                      ),
                  ],
                );
              },
            ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 15),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.ink : AppColors.hairline,
          ),
        ),
        child: Text(
          label,
          style: AppTheme.sans(
            size: 12,
            weight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.inkSoft,
          ),
        ),
      ),
    );
  }
}

class _MilestoneTile extends StatelessWidget {
  const _MilestoneTile({
    required this.milestone,
    required this.achieved,
    required this.achievedDate,
    required this.childAgeMonths,
    required this.onToggle,
  });

  final MilestoneDef milestone;
  final bool achieved;
  final DateTime? achievedDate;
  final double childAgeMonths;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    // Terlambat bila sudah lewat jendela wajar dan belum tercapai.
    final overdue = !achieved && childAgeMonths > milestone.windowEndMonths;
    final upcoming = childAgeMonths < milestone.typicalMonths - 2;

    return LuxeCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          // Checkbox emas kustom.
          GestureDetector(
            onTap: () => onToggle(!achieved),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                gradient: achieved ? AppColors.goldGradient : null,
                color: achieved ? null : AppColors.pearl,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: achieved ? Colors.transparent : AppColors.hairline,
                  width: 1.6,
                ),
              ),
              child: achieved
                  ? const Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: Colors.white,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  milestone.title,
                  style: AppTheme.sans(
                    size: 13.5,
                    weight: FontWeight.w700,
                    color: achieved ? AppColors.inkSoft : AppColors.ink,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.goldMist,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        milestone.category.label,
                        style: AppTheme.sans(
                          size: 9.5,
                          weight: FontWeight.w800,
                          color: AppColors.goldDeep,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'khas ${milestone.typicalMonths} bln • wajar s.d. ${milestone.windowEndMonths} bln',
                      style: AppTheme.sans(
                        size: 10.5,
                        weight: FontWeight.w600,
                        color: AppColors.inkFaint,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (overdue)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(
                Icons.priority_high_rounded,
                size: 18,
                color: AppColors.warn,
              ),
            )
          else if (upcoming)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(
                Icons.schedule_rounded,
                size: 16,
                color: AppColors.inkFaint,
              ),
            ),
        ],
      ),
    );
  }
}
