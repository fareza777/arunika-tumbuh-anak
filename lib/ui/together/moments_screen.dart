import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/moment.dart';
import '../../state/together_providers.dart';
import '../widgets/editorial_card.dart';
import '../widgets/journal_components.dart';
import 'moment_detail_screen.dart';

class MomentsScreen extends ConsumerStatefulWidget {
  const MomentsScreen({super.key, required this.onOpenMoment});
  final VoidCallback onOpenMoment;
  @override
  ConsumerState<MomentsScreen> createState() => _MomentsScreenState();
}

class _MomentsScreenState extends ConsumerState<MomentsScreen> {
  MomentTag? _filter;
  final _search = TextEditingController();
  String _query = '';
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _reset() {
    _search.clear();
    setState(() {
      _query = '';
      _filter = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final moments = ref.watch(momentsProvider);
    return JournalPage(
      onRefresh: () async {
        ref.invalidate(momentsProvider);
        try {
          await ref.read(momentsProvider.future);
        } catch (_) {
          /* Inline retry. */
        }
      },
      slivers: [
        JournalBlock(
          child: JournalHeader(
            eyebrow: 'JURNAL KELUARGA',
            title: 'Momen',
            subtitle: 'Buka kembali cerita yang ingin kalian ingat.',
            action: IconButton.filled(
              tooltip: 'Catat momen',
              onPressed: widget.onOpenMoment,
              icon: const Icon(Icons.add),
            ),
          ),
        ),
        JournalBlock(
          bottom: 12,
          child: TextField(
            controller: _search,
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Cari judul atau cerita',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Hapus pencarian',
                      onPressed: () {
                        _search.clear();
                        setState(() => _query = '');
                      },
                      icon: const Icon(Icons.close),
                    ),
            ),
          ),
        ),
        JournalBlock(
          bottom: 16,
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              ChoiceChip(
                label: const Text('Semua'),
                selected: _filter == null,
                onSelected: (_) => setState(() => _filter = null),
              ),
              for (final tag in MomentTag.values)
                ChoiceChip(
                  label: Text(tag.label),
                  selected: _filter == tag,
                  onSelected: (_) => setState(() => _filter = tag),
                ),
            ],
          ),
        ),
        moments.when(
          loading: () => const JournalBlock(child: JournalLoading()),
          error: (_, _) => JournalBlock(
            child: JournalNotice(
              error: true,
              title: 'Arsip belum terbuka',
              message: 'Catatan tetap tersimpan. Coba muat kembali.',
              action: 'Coba lagi',
              onAction: () => ref.invalidate(momentsProvider),
            ),
          ),
          data: (items) {
            final filtered = items
                .where(
                  (m) =>
                      (_filter == null || m.tag == _filter) &&
                      ('${m.title} ${m.note}'.toLowerCase().contains(_query)),
                )
                .toList();
            if (filtered.isEmpty) {
              return JournalBlock(
                child: JournalNotice(
                  title: items.isEmpty
                      ? 'Cerita pertama dimulai di sini'
                      : 'Belum ada yang cocok',
                  message: items.isEmpty
                      ? 'Simpan satu kalimat, kejadian lucu, atau foto hari ini. Semuanya bisa dibaca kembali kapan saja.'
                      : 'Coba kata lain atau tampilkan semua suasana.',
                  action: items.isEmpty
                      ? 'Catat momen pertama'
                      : 'Reset pencarian',
                  onAction: items.isEmpty ? widget.onOpenMoment : _reset,
                  icon: items.isEmpty
                      ? Icons.auto_stories_outlined
                      : Icons.search_off,
                ),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final m = filtered[index];
                  final month = DateFormat(
                    'MMMM yyyy',
                    'id_ID',
                  ).format(m.capturedAt);
                  final newMonth =
                      index == 0 ||
                      DateFormat(
                            'MMMM yyyy',
                            'id_ID',
                          ).format(filtered[index - 1].capturedAt) !=
                          month;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (newMonth)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 12, 0, 14),
                          child: Text(month, style: AppTheme.serif(size: 23)),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: MomentJournalCard(moment: m),
                      ),
                    ],
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

class MomentJournalCard extends StatelessWidget {
  const MomentJournalCard({super.key, required this.moment});
  final Moment moment;
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return EditorialCard(
      shadow: false,
      padding: EdgeInsets.zero,
      semanticLabel: 'Baca ${moment.title}',
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => MomentDetailScreen(moment: moment),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (moment.photoPath != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(26),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.file(
                  File(moment.photoPath!),
                  fit: BoxFit.cover,
                  cacheWidth: 900,
                  semanticLabel: 'Foto momen ${moment.title}',
                  errorBuilder: (_, _, _) => Container(
                    color: c.surfaceContainerHighest,
                    child: const Center(
                      child: Icon(Icons.image_not_supported_outlined, size: 32),
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Text(
                      moment.tag.label,
                      style: TextStyle(
                        color: c.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      DateFormat(
                        'EEE, d MMM yyyy',
                        'id_ID',
                      ).format(moment.capturedAt),
                      style: TextStyle(color: c.onSurfaceVariant, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  moment.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.serif(size: 24, height: 1.25),
                ),
                const SizedBox(height: 8),
                Text(
                  moment.note,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(height: 1.6, color: c.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Baca cerita',
                      style: TextStyle(
                        color: c.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 18, color: c.primary),
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
