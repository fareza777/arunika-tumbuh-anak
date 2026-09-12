import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/family_member.dart';
import '../../data/models/moment.dart';
import '../../domain/together/recap_service.dart';
import '../../state/app_settings.dart';
import '../../state/together_providers.dart';
import '../settings/settings_screen.dart';
import '../widgets/editorial_card.dart';
import '../widgets/journal_components.dart';
import 'family_member_editor_sheet.dart';
import 'moments_screen.dart';

class GardenScreen extends ConsumerWidget {
  const GardenScreen({super.key});
  void _edit(BuildContext context, FamilyMember? member) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        enableDrag: false,
        isDismissible: false,
        builder: (_) => FamilyMemberEditorSheet(initial: member),
      );
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(familyMembersProvider);
    final moments = ref.watch(momentsProvider);
    final recap = ref.watch(recapProvider);
    final settings = ref.watch(settingsProvider);
    final c = Theme.of(context).colorScheme;
    return JournalPage(
      onRefresh: () async {
        ref.invalidate(familyMembersProvider);
        ref.invalidate(momentsProvider);
        ref.invalidate(recapProvider);
        try {
          await ref.read(familyMembersProvider.future);
        } catch (_) {
          /* Inline retry. */
        }
      },
      slivers: [
        JournalBlock(
          child: JournalHeader(
            eyebrow: 'TUMBUH BERSAMA',
            title: 'Keluarga',
            subtitle: 'Orang-orang di balik cerita dan kebiasaan kalian.',
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
          child: EditorialCard(
            shadow: false,
            color: c.tertiaryContainer,
            borderColor: Colors.transparent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.wb_sunny_outlined,
                  size: 38,
                  color: c.onTertiaryContainer,
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compactHeadline =
                        constraints.maxWidth < 400 &&
                        MediaQuery.textScalerOf(context).scale(14) > 20;
                    return Text(
                      settings.familyName,
                      style: AppTheme.serif(
                        size: compactHeadline ? 22 : 30,
                        height: 1.2,
                        color: c.onTertiaryContainer,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                Text(
                  'Ruang untuk mengingat yang sederhana.',
                  style: TextStyle(color: c.onTertiaryContainer, height: 1.5),
                ),
                const SizedBox(height: 20),
                recap.maybeWhen(
                  data: (value) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      WeekPresenceStrip(days: value.week),
                      const SizedBox(height: 20),
                    ],
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
                members.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, _) => const Text('Daftar anggota belum terbaca.'),
                  data: (people) => Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final person in people.take(8))
                        Tooltip(
                          message: person.name,
                          child: _FamilyAvatar(
                            person: person,
                            background: c.surface,
                            foreground: c.primary,
                          ),
                        ),
                      if (people.length > 8)
                        CircleAvatar(
                          backgroundColor: c.surface,
                          child: Text('+${people.length - 8}'),
                        ),
                      if (people.isEmpty)
                        OutlinedButton.icon(
                          onPressed: () => _edit(context, null),
                          icon: const Icon(Icons.person_add_alt),
                          label: const Text('Tambah anggota'),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                moments.when(
                  loading: () => const Text('Memuat cerita…'),
                  error: (_, _) => const Text('Jumlah cerita belum terbaca.'),
                  data: (items) => Text(
                    '${items.length} momen tersimpan di perangkat ini',
                    style: TextStyle(
                      color: c.onTertiaryContainer,
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        JournalBlock(
          bottom: 12,
          child: const JournalSection(title: 'Cerita tujuh hari terakhir'),
        ),
        JournalBlock(
          child: recap.when(
            loading: () => const JournalLoading(),
            error: (_, _) => JournalNotice(
              error: true,
              title: 'Ringkasan belum terbuka',
              message: 'Coba muat kembali cerita keluarga.',
              action: 'Coba lagi',
              onAction: () => ref.invalidate(recapProvider),
            ),
            data: (value) => Column(
              children: [
                moments.maybeWhen(
                  data: (items) {
                    final featured = _featuredMoment(items, value);
                    if (featured == null) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: MomentJournalCard(moment: featured),
                    );
                  },
                  orElse: () => const SizedBox.shrink(),
                ),
                for (final card in value.cards)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: EditorialCard(
                      shadow: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            card.eyebrow,
                            style: AppTheme.sans(
                              size: 12,
                              weight: FontWeight.w700,
                              color: c.secondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            card.title,
                            style: AppTheme.serif(size: 23, height: 1.25),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            card.detail,
                            style: TextStyle(
                              color: c.onSurfaceVariant,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        JournalBlock(
          bottom: 12,
          child: JournalSection(
            title: 'Anggota keluarga',
            action: 'Tambah',
            onAction: () => _edit(context, null),
          ),
        ),
        members.when(
          loading: () => const JournalBlock(child: JournalLoading()),
          error: (_, _) => JournalBlock(
            child: JournalNotice(
              error: true,
              title: 'Anggota belum terbuka',
              message: 'Coba muat kembali daftar anggota.',
              action: 'Coba lagi',
              onAction: () => ref.invalidate(familyMembersProvider),
            ),
          ),
          data: (people) => people.isEmpty
              ? JournalBlock(
                  child: JournalNotice(
                    title: 'Siapa yang hadir dalam ceritamu?',
                    message:
                        'Tambahkan nama panggilan. Anggota membantu memberi konteks pada setiap momen.',
                    action: 'Tambah anggota',
                    onAction: () => _edit(context, null),
                    icon: Icons.people_outline,
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList.builder(
                    itemCount: people.length,
                    itemBuilder: (_, i) {
                      final person = people[i];
                      final count = moments.valueOrNull
                          ?.where((m) => m.memberId == person.id)
                          .length;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: EditorialCard(
                          shadow: false,
                          padding: const EdgeInsets.all(8),
                          onTap: () => _edit(context, person),
                          semanticLabel: 'Edit anggota ${person.name}',
                          child: ListTile(
                            leading: _FamilyAvatar(
                              person: person,
                              background: c.secondaryContainer,
                              foreground: c.onSecondaryContainer,
                            ),
                            title: Text(
                              person.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              '${person.roleLabel}${count == null ? '' : ' · $count momen'}',
                            ),
                            trailing: const Icon(Icons.edit_outlined, size: 20),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

Moment? _featuredMoment(List<Moment> items, WeeklyRecap recap) {
  if (recap.week.isEmpty) return null;
  final start = recap.week.first.date;
  final end = recap.week.last.date;
  for (final moment in items) {
    final day = DateTime(
      moment.capturedAt.year,
      moment.capturedAt.month,
      moment.capturedAt.day,
    );
    if (!day.isBefore(start) && !day.isAfter(end)) return moment;
  }
  return null;
}

class _FamilyAvatar extends StatelessWidget {
  const _FamilyAvatar({
    required this.person,
    required this.background,
    required this.foreground,
  });
  final FamilyMember person;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final path = person.photoPath?.trim();
    final initial =
        person.name.characters.firstOrNull?.toUpperCase() ?? '?';
    if (path == null || path.isEmpty) {
      return CircleAvatar(
        backgroundColor: background,
        foregroundColor: foreground,
        child: Text(initial),
      );
    }
    return CircleAvatar(
      backgroundColor: background,
      foregroundColor: foreground,
      child: ClipOval(
        child: Image.file(
          File(path),
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) =>
              Center(child: Text(initial, style: TextStyle(color: foreground))),
        ),
      ),
    );
  }
}
