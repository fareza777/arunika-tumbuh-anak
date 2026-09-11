import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/ritual.dart';
import '../../state/app_settings.dart';
import '../../state/together_providers.dart';
import '../settings/settings_screen.dart';
import '../widgets/editorial_card.dart';
import '../widgets/journal_components.dart';
import 'moment_detail_screen.dart';
import 'rituals_screen.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({
    super.key,
    required this.onOpenMoment,
    required this.onOpenRitual,
    this.onOpenRituals,
    this.onOpenMoments,
    this.onOpenGarden,
  });
  final VoidCallback onOpenMoment;
  final VoidCallback onOpenRitual;
  final VoidCallback? onOpenRituals;
  final VoidCallback? onOpenMoments;
  final VoidCallback? onOpenGarden;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final now = ref.watch(journalTodayProvider);
    final rituals = ref.watch(todayRitualsProvider);
    final completed = ref.watch(todayCompletedRitualIdsProvider);
    final moments = ref.watch(momentsProvider);
    final recap = ref.watch(recapProvider);
    final c = Theme.of(context).colorScheme;
    final viewRituals = onOpenRituals ?? onOpenRitual;
    return JournalPage(
      onRefresh: () async {
        ref.invalidate(journalTodayProvider);
        ref.invalidate(todayRitualsProvider);
        ref.invalidate(todayCompletedRitualIdsProvider);
        ref.invalidate(momentsProvider);
        ref.invalidate(recapProvider);
        try {
          await Future.wait([
            ref.read(todayRitualsProvider.future),
            ref.read(momentsProvider.future),
          ]);
        } catch (_) {
          /* Each section displays its retry state. */
        }
      },
      slivers: [
        JournalBlock(
          child: JournalHeader(
            eyebrow: DateFormat('EEEE, d MMMM', 'id_ID').format(now),
            title: settings.familyName,
            subtitle: 'Satu kebiasaan kecil. Satu cerita untuk diingat.',
            action: IconButton.filledTonal(
              tooltip: 'Pengaturan',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
              ),
              icon: const Icon(Icons.settings_outlined),
            ),
          ),
        ),
        JournalBlock(
          child: rituals.when(
            loading: () => const JournalLoading(),
            error: (_, _) => JournalNotice(
              error: true,
              title: 'Kebiasaan belum terbuka',
              message: 'Catatan tetap tersimpan. Coba muat kembali.',
              action: 'Coba lagi',
              onAction: () => ref.invalidate(todayRitualsProvider),
            ),
            data: (items) => completed.when(
              loading: () => const JournalLoading(),
              error: (_, _) => JournalNotice(
                error: true,
                title: 'Progres belum terbaca',
                message: 'Muat ulang sebelum menandai kebiasaan.',
                action: 'Coba lagi',
                onAction: () => ref.invalidate(todayCompletedRitualIdsProvider),
              ),
              data: (done) => _DailyCard(
                rituals: items,
                completed: done,
                onView: viewRituals,
              ),
            ),
          ),
        ),
        JournalBlock(
          child: EditorialCard(
            shadow: false,
            color: c.primaryContainer,
            borderColor: Colors.transparent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.edit_note, color: c.onPrimaryContainer),
                    const SizedBox(width: 8),
                    Text(
                      'Jurnal hari ini',
                      style: TextStyle(
                        color: c.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _prompts[now.weekday - 1],
                  style: AppTheme.serif(
                    size: 24,
                    height: 1.3,
                    color: c.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Satu kalimat cukup. Foto boleh menyusul.',
                  style: TextStyle(color: c.onPrimaryContainer, height: 1.5),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: onOpenMoment,
                  icon: const Icon(Icons.add),
                  label: const Text('Catat momen'),
                ),
              ],
            ),
          ),
        ),
        JournalBlock(
          bottom: 12,
          child: JournalSection(
            title: 'Tujuh hari terakhir',
            action: 'Ringkasan',
            onAction: onOpenGarden,
          ),
        ),
        JournalBlock(
          child: recap.when(
            loading: () => const JournalLoading(),
            error: (_, _) => JournalNotice(
              error: true,
              title: 'Ringkasan belum terbaca',
              message: 'Coba muat kembali catatan minggu ini.',
              action: 'Coba lagi',
              onAction: () => ref.invalidate(recapProvider),
            ),
            data: (value) => LayoutBuilder(
              builder: (context, constraints) {
                final largeText =
                    MediaQuery.textScalerOf(context).scale(14) > 20;
                final columns = largeText
                    ? 1
                    : constraints.maxWidth >= 348
                    ? 3
                    : 2;
                final width =
                    (constraints.maxWidth - 10 * (columns - 1)) / columns;
                final cards = [
                  _Count(
                    value: value.momentCount,
                    label: 'Momen',
                    icon: Icons.auto_stories_outlined,
                  ),
                  _Count(
                    value: value.ritualCount,
                    label: 'Kebiasaan',
                    icon: Icons.check_circle_outline,
                  ),
                  _Count(
                    value: value.activeDays,
                    label: 'Hari bersama',
                    icon: Icons.calendar_today_outlined,
                  ),
                ];
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final card in cards)
                      SizedBox(width: width, child: card),
                  ],
                );
              },
            ),
          ),
        ),
        JournalBlock(
          bottom: 12,
          child: JournalSection(
            title: 'Terakhir disimpan',
            action: 'Lihat semua',
            onAction: onOpenMoments ?? onOpenMoment,
          ),
        ),
        JournalBlock(
          child: moments.when(
            loading: () => const JournalLoading(),
            error: (_, _) => JournalNotice(
              error: true,
              title: 'Momen belum terbuka',
              message: 'Coba muat kembali arsip keluarga.',
              action: 'Coba lagi',
              onAction: () => ref.invalidate(momentsProvider),
            ),
            data: (items) {
              if (items.isEmpty) {
                return JournalNotice(
                  title: 'Cerita pertama menunggu',
                  message:
                      'Simpan kejadian kecil yang ingin kalian baca lagi nanti.',
                  action: 'Tulis cerita pertama',
                  onAction: onOpenMoment,
                );
              }
              final moment = items.first;
              return EditorialCard(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => MomentDetailScreen(moment: moment),
                  ),
                ),
                semanticLabel: 'Baca ${moment.title}',
                shadow: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${moment.tag.label} · ${DateFormat('d MMM yyyy', 'id_ID').format(moment.capturedAt)}',
                      style: TextStyle(color: c.primary, fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      moment.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.serif(size: 23),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      moment.note,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(height: 1.6, color: c.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),
                    const Text('Baca cerita →'),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  static const _prompts = [
    'Apa yang membuat kalian tersenyum hari ini?',
    'Hal kecil apa yang kalian pelajari bersama?',
    'Kalimat apa yang ingin kamu ingat lagi?',
    'Siapa yang membuat hari ini lebih hangat?',
    'Apa yang paling kamu syukuri hari ini?',
    'Jeda bersama apa yang terasa menyenangkan?',
    'Cerita apa yang ingin dibawa ke minggu depan?',
  ];
}

class _DailyCard extends StatelessWidget {
  const _DailyCard({
    required this.rituals,
    required this.completed,
    required this.onView,
  });
  final List<Ritual> rituals;
  final Set<String> completed;
  final VoidCallback onView;
  @override
  Widget build(BuildContext context) {
    if (rituals.isEmpty) {
      return JournalNotice(
        title: 'Hari ini tanpa jadwal',
        message:
            'Lihat kebiasaan keluarga atau pilih satu hal kecil untuk dilakukan bersama.',
        action: 'Lihat kebiasaan',
        onAction: onView,
        icon: Icons.wb_sunny_outlined,
      );
    }
    final count = rituals.where((r) => completed.contains(r.id)).length;
    final pending = rituals.where((r) => !completed.contains(r.id)).toList();
    final c = Theme.of(context).colorScheme;
    return EditorialCard(
      shadow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Kebiasaan hari ini', style: AppTheme.serif(size: 23)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: count / rituals.length,
                    minHeight: 7,
                    color: c.secondary,
                    backgroundColor: c.secondaryContainer,
                    semanticsLabel:
                        '$count dari ${rituals.length} kebiasaan selesai',
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                '$count / ${rituals.length}',
                style: AppTheme.sans(
                  size: 16,
                  weight: FontWeight.w800,
                  color: c.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (pending.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Semua jadwal hari ini sudah dilakukan. Nikmati waktu bersama.',
                style: TextStyle(color: c.onSurfaceVariant, height: 1.5),
              ),
            )
          else
            RitualRow(
              ritual: pending.first,
              completed: false,
              onEdit: onView,
              compact: true,
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onView,
              child: const Text('Lihat semua kebiasaan'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.value, required this.label, required this.icon});
  final int value;
  final String label;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.secondaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: c.onSecondaryContainer),
          const SizedBox(height: 12),
          Text(
            '$value',
            style: AppTheme.serif(size: 30, color: c.onSecondaryContainer),
          ),
          Text(
            label,
            style: AppTheme.sans(size: 12, color: c.onSecondaryContainer),
          ),
        ],
      ),
    );
  }
}
