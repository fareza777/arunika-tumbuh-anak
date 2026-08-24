import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/luxe_card.dart';
import '../../core/widgets/stat_ring.dart';
import '../../data/models/measurement.dart';
import '../../state/app_settings.dart';
import '../../state/providers.dart';
import '../measure/add_measurement_screen.dart';

/// Riwayat pengukuran anak terpilih, dikelompokkan per bulan.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(selectedChildProvider);
    final measurementsAsync = ref.watch(measurementsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Pengukuran')),
      body: child == null
          ? const EmptyState(
              icon: Icons.history_rounded,
              title: 'Belum Ada Anak Terpilih',
              message:
                  'Tambahkan profil anak untuk melihat riwayat pengukurannya.',
            )
          : measurementsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Terjadi kesalahan: $e')),
              data: (measurements) {
                if (measurements.isEmpty) {
                  return EmptyState(
                    icon: Icons.fact_check_outlined,
                    title: 'Belum Ada Catatan',
                    message:
                        'Pengukuran ${child.name} akan tampil di sini. Tekan tombol + untuk mencatat.',
                  );
                }
                return _HistoryList(
                  measurements: measurements.reversed.toList(),
                );
              },
            ),
    );
  }
}

class _HistoryList extends ConsumerWidget {
  const _HistoryList({required this.measurements});

  /// Terurut terbaru dulu.
  final List<Measurement> measurements;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Kelompokkan per bulan-tahun.
    final groups = <String, List<Measurement>>{};
    for (final m in measurements) {
      groups.putIfAbsent(Format.monthYear(m.date), () => []).add(m);
    }

    final entries = groups.entries.toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
      itemCount: entries.length,
      itemBuilder: (context, i) {
        final group = entries[i];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 14, 4, 10),
              child: Text(
                group.key,
                style: AppTheme.sans(
                  size: 12,
                  weight: FontWeight.w800,
                  color: AppColors.goldDeep,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            for (final m in group.value) ...[
              _HistoryTile(measurement: m),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }
}

class _HistoryTile extends ConsumerWidget {
  const _HistoryTile({required this.measurement});

  final Measurement measurement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(selectedChildProvider);
    final settings = ref.watch(settingsProvider);

    final analysis = child == null
        ? null
        : ref
              .read(zScoreServiceProvider)
              .analyze(
                child: child,
                measurement: measurement,
                standard: settings.standard,
              );

    return Dismissible(
      key: ValueKey(measurement.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        decoration: BoxDecoration(
          color: AppColors.dangerSoft,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: AppColors.danger,
        ),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Hapus Pengukuran?'),
            content: Text(
              'Catatan ${Format.date(measurement.date)} akan dihapus permanen.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                child: const Text('Hapus'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        ref.read(measurementActionsProvider).delete(measurement.id);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Pengukuran dihapus.')));
      },
      child: LuxeCard(
        padding: const EdgeInsets.all(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AddMeasurementScreen(existing: measurement),
            fullscreenDialog: true,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconTile(
                  icon: Icons.event_note_rounded,
                  color: AppColors.gold,
                  size: 42,
                  iconSize: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Format.dateWithDay(measurement.date),
                        style: AppTheme.sans(
                          size: 13.5,
                          weight: FontWeight.w800,
                        ),
                      ),
                      if (child != null)
                        Text(
                          'usia ${Format.ageFromMonths(child.ageMonthsAt(measurement.date))}',
                          style: AppTheme.sans(
                            size: 11.5,
                            color: AppColors.inkFaint,
                          ),
                        ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.edit_outlined,
                  size: 17,
                  color: AppColors.inkFaint,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (measurement.weight != null)
                  _ValueChip(label: 'BB', value: Format.kg(measurement.weight)),
                if (measurement.height != null)
                  _ValueChip(label: 'TB', value: Format.cm(measurement.height)),
                if (measurement.bmi != null)
                  _ValueChip(
                    label: 'IMT',
                    value: measurement.bmi!
                        .toStringAsFixed(1)
                        .replaceAll('.', ','),
                  ),
                if (measurement.head != null)
                  _ValueChip(label: 'LK', value: Format.cm(measurement.head)),
                if (measurement.muac != null)
                  _ValueChip(label: 'LILA', value: Format.cm(measurement.muac)),
              ],
            ),
            if (analysis != null && analysis.results.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final r in analysis.results)
                    ZBadge(
                      label: '${r.indicator.shortLabel} ${Format.z(r.z)}',
                      color: r.classification.color,
                      dense: true,
                    ),
                ],
              ),
            ],
            if (measurement.note != null && measurement.note!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.notes_rounded,
                    size: 14,
                    color: AppColors.inkFaint,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      measurement.note!,
                      style: AppTheme.sans(
                        size: 11.5,
                        color: AppColors.inkSoft,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ValueChip extends StatelessWidget {
  const _ValueChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.pearl,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.hairline),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label  ',
              style: AppTheme.sans(
                size: 10,
                weight: FontWeight.w800,
                color: AppColors.inkFaint,
                letterSpacing: 0.6,
              ),
            ),
            TextSpan(
              text: value,
              style: AppTheme.sans(
                size: 12.5,
                weight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
