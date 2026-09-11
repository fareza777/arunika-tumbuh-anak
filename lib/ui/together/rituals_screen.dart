import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/ritual.dart';
import '../../state/together_providers.dart';
import '../widgets/editorial_card.dart';
import '../widgets/journal_components.dart';
import 'ritual_editor_sheet.dart';

class RitualsScreen extends ConsumerStatefulWidget {
  const RitualsScreen({super.key, required this.onOpenRitual});
  final VoidCallback onOpenRitual;
  @override
  ConsumerState<RitualsScreen> createState() => _RitualsScreenState();
}

class _RitualsScreenState extends ConsumerState<RitualsScreen> {
  var _filter = 0;
  void _edit(Ritual ritual) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    enableDrag: false,
    isDismissible: false,
    builder: (_) => RitualEditorSheet(initial: ritual),
  );
  @override
  Widget build(BuildContext context) {
    final rituals = ref.watch(
      _filter == 2 ? archivedRitualsProvider : ritualsProvider,
    );
    final done = ref.watch(todayCompletedRitualIdsProvider);
    final today = ref.watch(journalTodayProvider);
    return JournalPage(
      onRefresh: () async {
        ref.invalidate(ritualsProvider);
        ref.invalidate(archivedRitualsProvider);
        ref.invalidate(todayCompletedRitualIdsProvider);
        try {
          await ref.read(ritualsProvider.future);
        } catch (_) {
          /* Inline retry. */
        }
      },
      slivers: [
        JournalBlock(
          child: JournalHeader(
            title: 'Kebiasaan',
            subtitle:
                'Pilih waktu bersama yang ingin kalian ulangi. Tandai setelah dilakukan.',
            eyebrow: 'SEDIKIT, TAPI BERARTI',
            action: IconButton.filled(
              tooltip: 'Buat kebiasaan',
              onPressed: widget.onOpenRitual,
              icon: const Icon(Icons.add),
            ),
          ),
        ),
        JournalBlock(
          bottom: 16,
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (var i = 0; i < 3; i++)
                ChoiceChip(
                  label: Text(['Hari ini', 'Semua', 'Arsip'][i]),
                  selected: _filter == i,
                  onSelected: (_) => setState(() => _filter = i),
                ),
            ],
          ),
        ),
        rituals.when(
          loading: () => const JournalBlock(child: JournalLoading()),
          error: (_, _) => JournalBlock(
            child: JournalNotice(
              error: true,
              title: 'Kebiasaan belum terbuka',
              message: 'Coba muat kembali daftar kebiasaan.',
              action: 'Coba lagi',
              onAction: () {
                ref.invalidate(ritualsProvider);
                ref.invalidate(archivedRitualsProvider);
              },
            ),
          ),
          data: (items) {
            final shown =
                items
                    .where((r) => _filter != 0 || r.isScheduledFor(today))
                    .toList()
                  ..sort(
                    (a, b) => a.timeOfDay.index.compareTo(b.timeOfDay.index),
                  );
            if (shown.isEmpty) {
              return JournalBlock(
                child: JournalNotice(
                  icon: _filter == 2
                      ? Icons.archive_outlined
                      : Icons.spa_outlined,
                  title: _filter == 2
                      ? 'Belum ada arsip'
                      : _filter == 0 && items.isNotEmpty
                      ? 'Hari ini tanpa jadwal'
                      : 'Mulai dari satu kebiasaan',
                  message: _filter == 2
                      ? 'Kebiasaan yang diarsipkan tetap menyimpan riwayat dan bisa dipulihkan.'
                      : 'Membaca sebelum tidur atau berjalan sebentar bisa jadi awal. Pilih yang terasa ringan.',
                  action: _filter == 2 ? null : 'Buat kebiasaan',
                  onAction: widget.onOpenRitual,
                ),
              );
            }
            if (done.hasError && _filter != 2) {
              return JournalBlock(
                child: JournalNotice(
                  error: true,
                  title: 'Progres belum terbaca',
                  message: 'Muat ulang sebelum menandai kebiasaan.',
                  action: 'Coba lagi',
                  onAction: () =>
                      ref.invalidate(todayCompletedRitualIdsProvider),
                ),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList.builder(
                itemCount: shown.length,
                itemBuilder: (_, i) {
                  final ritual = shown[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: EditorialCard(
                      shadow: false,
                      padding: const EdgeInsets.all(8),
                      child: RitualRow(
                        key: ValueKey(ritual.id),
                        ritual: ritual,
                        completed:
                            done.valueOrNull?.contains(ritual.id) ?? false,
                        loading: done.isLoading,
                        onEdit: () => _edit(ritual),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class RitualRow extends ConsumerStatefulWidget {
  const RitualRow({
    super.key,
    required this.ritual,
    required this.completed,
    required this.onEdit,
    this.compact = false,
    this.loading = false,
  });
  final Ritual ritual;
  final bool completed;
  final bool compact;
  final bool loading;
  final VoidCallback onEdit;
  @override
  ConsumerState<RitualRow> createState() => _RitualRowState();
}

class _RitualRowState extends ConsumerState<RitualRow> {
  var _saving = false;
  Future<void> _check(bool value) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(togetherActionsProvider)
          .setRitualCheckIn(widget.ritual.id, value);
    } catch (_) {
      if (mounted) journalMessage(context, 'Tanda belum tersimpan. Coba lagi.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(togetherActionsProvider)
          .saveRitual(widget.ritual.copyWith(isArchived: false));
      if (mounted) journalMessage(context, 'Kebiasaan dipulihkan.');
    } catch (_) {
      if (mounted) {
        journalMessage(context, 'Belum dapat dipulihkan. Coba lagi.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final r = widget.ritual;
    final scheduled = r.isScheduledFor(ref.watch(journalTodayProvider));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (r.isArchived)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(Icons.archive_outlined),
            )
          else
            SizedBox(
              width: 48,
              height: 48,
              child: _saving
                  ? const Padding(
                      padding: EdgeInsets.all(13),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Checkbox(
                      value: widget.completed,
                      semanticLabel:
                          '${widget.completed ? 'Batalkan' : 'Tandai selesai'} ${r.title}',
                      activeColor: c.secondary,
                      onChanged: scheduled && !widget.loading
                          ? (v) => _check(v ?? false)
                          : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.title,
                    style: AppTheme.sans(
                      size: 15,
                      weight: FontWeight.w700,
                      color: widget.completed ? c.secondary : c.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${r.timeOfDay.label} · ${ritualDaysLabel(r.repeatDays)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: c.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  if (!scheduled && !r.isArchived)
                    Text(
                      'Tidak dijadwalkan hari ini',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: c.primary,
                      ),
                    ),
                  if (!widget.compact && r.description?.isNotEmpty == true)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        r.description!,
                        style: TextStyle(
                          fontSize: 13,
                          color: c.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ),
                  if (r.isArchived)
                    TextButton(
                      onPressed: _saving ? null : _restore,
                      child: const Text('Pulihkan kebiasaan'),
                    ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: widget.compact ? 'Lihat kebiasaan' : 'Edit kebiasaan',
            onPressed: _saving ? null : widget.onEdit,
            icon: Icon(
              widget.compact ? Icons.chevron_right : Icons.more_horiz,
              color: c.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

String ritualDaysLabel(Set<int> days) {
  if (days.length == 7) return 'Setiap hari';
  const labels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
  return (days.toList()..sort())
      .where((d) => d >= 1 && d <= 7)
      .map((d) => labels[d - 1])
      .join(', ');
}
