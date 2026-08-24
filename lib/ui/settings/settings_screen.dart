import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../app.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/luxe_card.dart';
import '../../core/widgets/section_header.dart';
import '../../domain/backup/backup_service.dart';
import '../../domain/notifications/notification_service.dart';
import '../../domain/standards/growth_standards.dart';
import '../../state/app_settings.dart';
import '../../state/monetization_provider.dart';
import '../../state/providers.dart';
import '../monetization/remove_ads_card.dart';

/// Pengaturan: standar rujukan default, pengingat pengukuran, tentang.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final child = ref.watch(selectedChildProvider);

    Future<void> applyReminder(AppSettings next) async {
      await notifier.update(next);
      final service = NotificationService.instance;
      if (next.reminderEnabled) {
        final granted = await service.requestPermission();
        if (!granted) {
          await notifier.update(next.copyWith(reminderEnabled: false));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Izin notifikasi ditolak oleh sistem.'),
              ),
            );
          }
          return;
        }
        await service.scheduleMeasurementReminders(
          intervalWeeks: next.reminderIntervalWeeks,
          hour: next.reminderHour,
          minute: next.reminderMinute,
          childName: child?.name ?? '',
        );
      } else {
        await service.cancelReminders();
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          // ── Standar rujukan ────────────────────────────────────────────
          const SectionHeader(title: 'Standar Pertumbuhan Default'),
          for (final standard in GrowthStandard.values)
            LuxeCard(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              borderColor: settings.standard == standard
                  ? AppColors.gold
                  : AppColors.hairline,
              onTap: () =>
                  notifier.update(settings.copyWith(standard: standard)),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: settings.standard == standard
                          ? AppColors.goldGradient
                          : null,
                      border: Border.all(
                        color: settings.standard == standard
                            ? Colors.transparent
                            : AppColors.inkFaint,
                        width: 1.6,
                      ),
                    ),
                    child: settings.standard == standard
                        ? const Icon(
                            Icons.check_rounded,
                            size: 15,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          standard.label,
                          style: AppTheme.sans(
                            size: 14,
                            weight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          standard.description,
                          style: AppTheme.sans(
                            size: 11,
                            color: AppColors.inkSoft,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),

          // ── Pengingat pengukuran ───────────────────────────────────────
          const SectionHeader(title: 'Pengingat Pengukuran'),
          LuxeCard(
            child: Column(
              children: [
                Row(
                  children: [
                    const IconTile(
                      icon: Icons.notifications_rounded,
                      color: AppColors.gold,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pengingat Rutin',
                            style: AppTheme.sans(
                              size: 14,
                              weight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            settings.reminderEnabled
                                ? 'Aktif • tiap ${settings.reminderIntervalWeeks} minggu • ${_timeLabel(settings)}'
                                : 'Nonaktif',
                            style: AppTheme.sans(
                              size: 11.5,
                              color: AppColors.inkSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: settings.reminderEnabled,
                      onChanged: (v) =>
                          applyReminder(settings.copyWith(reminderEnabled: v)),
                    ),
                  ],
                ),
                if (settings.reminderEnabled) ...[
                  const Divider(height: 26),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Interval',
                              style: AppTheme.sans(
                                size: 11.5,
                                weight: FontWeight.w700,
                                color: AppColors.inkSoft,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                for (final weeks in [1, 2, 4]) ...[
                                  _IntervalChip(
                                    label: weeks == 4
                                        ? 'Bulanan'
                                        : '$weeks mgg',
                                    selected:
                                        settings.reminderIntervalWeeks == weeks,
                                    onTap: () => applyReminder(
                                      settings.copyWith(
                                        reminderIntervalWeeks: weeks,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Jam',
                            style: AppTheme.sans(
                              size: 11.5,
                              weight: FontWeight.w700,
                              color: AppColors.inkSoft,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay(
                                  hour: settings.reminderHour,
                                  minute: settings.reminderMinute,
                                ),
                              );
                              if (picked != null) {
                                await applyReminder(
                                  settings.copyWith(
                                    reminderHour: picked.hour,
                                    reminderMinute: picked.minute,
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.goldMist,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.goldSoft),
                              ),
                              child: Text(
                                _timeLabel(settings),
                                style: AppTheme.sans(
                                  size: 14,
                                  weight: FontWeight.w800,
                                  color: AppColors.goldDeep,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Bebas iklan ──────────────────────────────────────────────
          const SectionHeader(title: 'Dukungan Arunika'),
          const RemoveAdsCard(),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () async {
              await ref
                  .read(monetizationProvider.notifier)
                  .showPrivacyOptions();
            },
            icon: const Icon(Icons.privacy_tip_outlined, size: 18),
            label: const Text('Kelola opsi privasi iklan'),
          ),
          const SizedBox(height: 24),

          // ── Cadangan & pemulihan ───────────────────────────────────────
          const SectionHeader(title: 'Cadangan & Pemulihan'),
          LuxeCard(
            child: Column(
              children: [
                _BackupRow(
                  icon: Icons.cloud_upload_rounded,
                  title: 'Cadangkan Data',
                  subtitle: 'Ekspor seluruh data anak ke berkas JSON',
                  onTap: () => _exportBackup(context, ref),
                ),
                const Divider(height: 24),
                _BackupRow(
                  icon: Icons.cloud_download_rounded,
                  title: 'Pulihkan Data',
                  subtitle: 'Impor cadangan — digabung, tidak menimpa data',
                  onTap: () => _restoreBackup(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Tentang ────────────────────────────────────────────────────
          const SectionHeader(title: 'Tentang Arunika'),
          LuxeCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: AppColors.goldGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.wb_sunny_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppIdentity.fullName,
                          style: AppTheme.serif(
                            size: 16,
                            weight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Versi ${AppIdentity.version}',
                          style: AppTheme.sans(
                            size: 11.5,
                            color: AppColors.inkFaint,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _AboutRow(
                  title: 'Sumber data',
                  body:
                      'WHO Child Growth Standards 2006, WHO Growth Reference 2007, dan CDC Growth Charts 2000 (tabel LMS resmi).',
                ),
                _AboutRow(
                  title: 'Klasifikasi',
                  body:
                      'Permenkes RI No. 2 Tahun 2020 tentang Standar Antropometri Anak.',
                ),
                _AboutRow(
                  title: 'Privasi',
                  body:
                      'Data inti anak tersimpan lokal. Iklan dan pembelian diproses oleh layanan pihak ketiga sesuai kebijakan mereka.',
                ),
                _AboutRow(
                  title: 'Penafian',
                  body:
                      'Aplikasi ini alat bantu pemantauan, bukan pengganti diagnosis tenaga kesehatan. Selalu konsultasikan kondisi anak ke dokter/bidan.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _timeLabel(AppSettings s) =>
      '${s.reminderHour.toString().padLeft(2, '0')}.${s.reminderMinute.toString().padLeft(2, '0')}';

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    try {
      final file = await BackupService().exportToFile();
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'Cadangan Data Arunika',
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal membuat cadangan: $e')));
      }
    }
  }

  Future<void> _restoreBackup(BuildContext context, WidgetRef ref) async {
    const typeGroup = XTypeGroup(label: 'Backup Arunika', extensions: ['json']);
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    final path = file?.path;
    if (path == null || !context.mounted) return;

    try {
      final summary = await BackupService().importFromFile(path);
      // Segarkan seluruh provider data.
      ref.invalidate(childrenProvider);
      ref.invalidate(measurementsProvider);
      ref.invalidate(milestoneStatusProvider);
      ref.invalidate(immunizationStatusProvider);
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(
            Icons.check_circle_rounded,
            color: AppColors.good,
            size: 32,
          ),
          title: const Text('Pemulihan Selesai'),
          content: Text(
            'Data baru yang ditambahkan:\n'
            '• ${summary.childrenAdded} profil anak\n'
            '• ${summary.measurementsAdded} pengukuran\n'
            '• ${summary.progressAdded} catatan milestone/imunisasi/gizi\n\n'
            'Data yang sudah ada tidak ditimpa.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Selesai'),
            ),
          ],
        ),
      );
    } on FormatException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memulihkan: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }
}

class _BackupRow extends StatelessWidget {
  const _BackupRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            IconTile(icon: icon, color: AppColors.gold),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.sans(size: 14, weight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTheme.sans(
                      size: 11,
                      color: AppColors.inkSoft,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.inkFaint),
          ],
        ),
      ),
    );
  }
}

class _IntervalChip extends StatelessWidget {
  const _IntervalChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : AppColors.pearl,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.ink : AppColors.hairline,
          ),
        ),
        child: Text(
          label,
          style: AppTheme.sans(
            size: 11.5,
            weight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.inkSoft,
          ),
        ),
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.sans(
              size: 12,
              weight: FontWeight.w800,
              color: AppColors.goldDeep,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            body,
            style: AppTheme.sans(
              size: 12,
              color: AppColors.inkSoft,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
