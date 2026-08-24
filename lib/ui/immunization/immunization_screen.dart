import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/luxe_card.dart';
import '../../core/widgets/section_header.dart';
import '../../domain/content/immunization_data.dart';
import '../../state/providers.dart';

/// Jadwal imunisasi nasional + rekomendasi IDAI dengan penanda selesai.
class ImmunizationScreen extends ConsumerWidget {
  const ImmunizationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(selectedChildProvider);
    final statusAsync = ref.watch(immunizationStatusProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Imunisasi')),
      body: child == null
          ? const EmptyState(
              icon: Icons.vaccines_rounded,
              title: 'Belum Ada Anak Terpilih',
              message:
                  'Tambahkan profil anak untuk memantau jadwal imunisasinya.',
            )
          : statusAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Terjadi kesalahan: $e')),
              data: (status) {
                final done = status.keys.toSet();
                final ageMonths = child.ageInMonths;

                final program = kVaccines.where((v) => !v.optional).toList()
                  ..sort((a, b) => a.ageMonths.compareTo(b.ageMonths));
                final optional = kVaccines.where((v) => v.optional).toList()
                  ..sort((a, b) => a.ageMonths.compareTo(b.ageMonths));

                final dueCount = program
                    .where(
                      (v) => !done.contains(v.id) && ageMonths >= v.ageMonths,
                    )
                    .length;

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                  children: [
                    if (dueCount > 0)
                      SoftCard(
                        color: AppColors.warnSoft,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.notifications_active_rounded,
                              size: 20,
                              color: AppColors.warn,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '$dueCount vaksin program sudah memasuki jadwal untuk ${child.name.split(' ').first}.',
                                style: AppTheme.sans(
                                  size: 12.5,
                                  weight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 18),
                    const SectionHeader(title: 'Program Nasional'),
                    for (final v in program)
                      _VaccineTile(
                        vaccine: v,
                        done: done.contains(v.id),
                        doneDate: status[v.id],
                        due: ageMonths >= v.ageMonths,
                        onToggle: (value) {
                          HapticFeedback.selectionClick();
                          ref
                              .read(progressActionsProvider)
                              .toggleImmunization(child.id, v.id, value);
                        },
                      ),
                    const SizedBox(height: 20),
                    const SectionHeader(title: 'Rekomendasi Tambahan IDAI'),
                    for (final v in optional)
                      _VaccineTile(
                        vaccine: v,
                        done: done.contains(v.id),
                        doneDate: status[v.id],
                        due: ageMonths >= v.ageMonths,
                        onToggle: (value) {
                          HapticFeedback.selectionClick();
                          ref
                              .read(progressActionsProvider)
                              .toggleImmunization(child.id, v.id, value);
                        },
                      ),
                    const SizedBox(height: 14),
                    Text(
                      'Jadwal mengacu pada program imunisasi rutin Kemenkes dan rekomendasi IDAI. Selalu konfirmasikan ke fasilitas kesehatan Anda.',
                      style: AppTheme.sans(
                        size: 11,
                        color: AppColors.inkFaint,
                        height: 1.5,
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _VaccineTile extends StatelessWidget {
  const _VaccineTile({
    required this.vaccine,
    required this.done,
    required this.doneDate,
    required this.due,
    required this.onToggle,
  });

  final VaccineDef vaccine;
  final bool done;
  final DateTime? doneDate;
  final bool due;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final statusColor = done
        ? AppColors.good
        : due
        ? AppColors.warn
        : AppColors.inkFaint;

    return LuxeCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => onToggle(!done),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                gradient: done ? AppColors.goldGradient : null,
                color: done ? null : AppColors.pearl,
                shape: BoxShape.circle,
                border: Border.all(
                  color: done ? Colors.transparent : AppColors.hairline,
                  width: 1.6,
                ),
              ),
              child: Icon(
                done ? Icons.check_rounded : Icons.vaccines_rounded,
                size: 16,
                color: done ? Colors.white : AppColors.inkFaint,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vaccine.name,
                  style: AppTheme.sans(
                    size: 13.5,
                    weight: FontWeight.w800,
                    color: done ? AppColors.inkSoft : AppColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  vaccine.protects,
                  style: AppTheme.sans(
                    size: 11,
                    color: AppColors.inkSoft,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      vaccine.ageLabel,
                      style: AppTheme.sans(
                        size: 10.5,
                        weight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                    if (done && doneDate != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '• selesai',
                        style: AppTheme.sans(
                          size: 10.5,
                          weight: FontWeight.w700,
                          color: AppColors.good,
                        ),
                      ),
                    ] else if (due) ...[
                      const SizedBox(width: 8),
                      Text(
                        '• jadwal tiba',
                        style: AppTheme.sans(
                          size: 10.5,
                          weight: FontWeight.w700,
                          color: AppColors.warn,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
