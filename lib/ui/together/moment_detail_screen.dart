import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/moment.dart';
import '../../state/together_providers.dart';
import '../widgets/journal_components.dart';
import 'moment_editor_screen.dart';

class MomentDetailScreen extends ConsumerStatefulWidget {
  const MomentDetailScreen({super.key, required this.moment});
  final Moment moment;
  @override
  ConsumerState<MomentDetailScreen> createState() => _MomentDetailScreenState();
}

class _MomentDetailScreenState extends ConsumerState<MomentDetailScreen> {
  bool _busy = false;
  Future<void> _delete(Moment moment) async {
    if (!await confirmJournalAction(
          context,
          title: 'Hapus momen ini?',
          message:
              'Cerita “${moment.title}” akan dihapus dari perangkat ini. Tindakan ini tidak bisa dibatalkan.',
          confirm: 'Hapus momen',
        ) ||
        !mounted) {
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(togetherActionsProvider).deleteMoment(moment.id);
      if (mounted) {
        journalMessage(context, 'Momen dihapus.');
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        journalMessage(context, 'Momen belum dapat dihapus. Coba lagi.');
      }
    }
  }

  Future<void> _share(Moment moment) async {
    setState(() => _busy = true);
    try {
      await SharePlus.instance.share(
        ShareParams(
          text:
              '${moment.title}\n${DateFormat('d MMMM yyyy', 'id_ID').format(moment.capturedAt)}\n\n${moment.note}',
          subject: moment.title,
        ),
      );
    } catch (_) {
      if (mounted) {
        journalMessage(context, 'Menu berbagi belum dapat dibuka. Coba lagi.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(momentsProvider).valueOrNull;
    final m =
        items?.where((m) => m.id == widget.moment.id).firstOrNull ??
        widget.moment;
    final members = ref.watch(familyMembersProvider).valueOrNull;
    final member = members?.where((v) => v.id == m.memberId).firstOrNull;
    final c = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cerita keluarga'),
        actions: [
          IconButton(
            tooltip: 'Edit momen',
            onPressed: _busy
                ? null
                : () => Navigator.of(context).push(
                    MaterialPageRoute<bool>(
                      builder: (_) => MomentEditorScreen(initial: m),
                    ),
                  ),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: JournalPage(
        slivers: [
          if (m.photoPath != null)
            JournalBlock(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.file(
                  File(m.photoPath!),
                  fit: BoxFit.contain,
                  semanticLabel: 'Foto ${m.title}',
                  errorBuilder: (_, _, _) => const JournalNotice(
                    title: 'Foto tidak tersedia',
                    message:
                        'Cerita tetap tersimpan. Kamu bisa memilih ulang foto lewat Edit.',
                    icon: Icons.image_not_supported_outlined,
                  ),
                ),
              ),
            ),
          JournalBlock(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${m.tag.label} · ${DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(m.capturedAt)}',
                  style: TextStyle(color: c.primary, height: 1.6),
                ),
                const SizedBox(height: 16),
                SelectableText(
                  m.title,
                  style: AppTheme.serif(size: 32, height: 1.25),
                ),
                if (member != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'Bersama ${member.name}',
                      style: TextStyle(color: c.onSurfaceVariant),
                    ),
                  ),
                const SizedBox(height: 22),
                SelectableText(
                  m.note,
                  style: AppTheme.sans(
                    size: 16,
                    height: 1.8,
                    color: c.onSurface,
                  ),
                ),
                const SizedBox(height: 32),
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _share(m),
                  icon: const Icon(Icons.ios_share_outlined),
                  label: const Text('Bagikan cerita'),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _busy ? null : () => _delete(m),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Hapus momen'),
                  style: TextButton.styleFrom(foregroundColor: c.error),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
