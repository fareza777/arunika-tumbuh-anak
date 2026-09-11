import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_selector/file_selector.dart';
import 'package:share_plus/share_plus.dart';
import '../../app.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/together/journal_backup_service.dart';
import '../../domain/together/scrapbook_pdf.dart';
import '../../state/app_settings.dart';
import '../../state/journal_reminder_provider.dart';
import '../../state/monetization_provider.dart';
import '../../state/together_providers.dart';
import '../monetization/remove_ads_card.dart';
import '../widgets/editorial_card.dart';
import '../widgets/journal_components.dart';
import 'privacy_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _busy = false;
  String _activity = '';
  Future<void> _run(String activity, Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _activity = activity;
    });
    try {
      await action();
    } on FormatException catch (error) {
      if (mounted) {
        journalMessage(
          context,
          'Berkas belum dapat diproses. ${error.message}',
        );
      }
    } catch (_) {
      if (mounted) {
        journalMessage(
          context,
          'Belum berhasil. Periksa ruang penyimpanan atau izin perangkat, lalu coba lagi.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _familyName() async {
    final old = ref.read(settingsProvider).familyName;
    final value = await showDialog<String>(
      context: context,
      builder: (_) => _FamilyNameDialog(initial: old),
    );
    if (value == null) return;
    await _run(
      'Menyimpan nama keluarga…',
      () => ref
          .read(settingsProvider.notifier)
          .update(ref.read(settingsProvider).copyWith(familyName: value)),
    );
  }

  Future<void> _reminder(bool enabled) => _run('Mengatur pengingat…', () async {
    final granted = await ref.read(journalReminderProvider).setEnabled(enabled);
    if (!mounted) return;
    journalMessage(
      context,
      !granted
          ? 'Izin notifikasi belum aktif. Izinkan Arunika di Pengaturan Android untuk menerima pengingat.'
          : enabled
          ? 'Pengingat harian aktif.'
          : 'Pengingat harian dimatikan.',
    );
  });
  Future<void> _time() async {
    final settings = ref.read(settingsProvider);
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: settings.journalReminderHour,
        minute: settings.journalReminderMinute,
      ),
    );
    if (time == null) return;
    await _run('Menyimpan waktu…', () async {
      final allowed = await ref
          .read(journalReminderProvider)
          .setTime(hour: time.hour, minute: time.minute);
      if (!allowed && mounted) {
        journalMessage(
          context,
          'Waktu tersimpan. Aktifkan izin notifikasi agar pengingat dapat berjalan.',
        );
      }
    });
  }

  Future<void> _backup() => _run('Menyiapkan cadangan beserta foto…', () async {
    var missing = 0;
    final file = await JournalBackupService().exportToFile(
      familyName: ref.read(settingsProvider).familyName,
      onMissingPhotos: (count) => missing = count,
    );
    if (!mounted) return;
    if (missing > 0 &&
        !await confirmJournalAction(
          context,
          title: '$missing foto tidak tersedia',
          message:
              'Foto lama yang sudah hilang tidak dapat disertakan. Semua cerita dan foto yang masih tersedia tetap dicadangkan.',
          confirm: 'Lanjutkan ekspor',
        )) {
      return;
    }
    if (!mounted) return;
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: 'Cadangan Arunika'),
    );
  });
  Future<void> _restore() async {
    await _run('Membuka cadangan…', () async {
      final file = await openFile(
        acceptedTypeGroups: const [
          XTypeGroup(
            label: 'Cadangan Arunika',
            extensions: ['json'],
            mimeTypes: ['application/json'],
          ),
        ],
      );
      if (file == null || !mounted) return;
      if (!await confirmJournalAction(
        context,
        title: 'Pulihkan cadangan?',
        message:
            'Berkas: ${file.name}\n\nCatatan baru akan digabungkan. Catatan dengan ID yang sama akan dilewati; data yang ada tidak ditimpa.',
        confirm: 'Pulihkan',
      )) {
        return;
      }
      final wasEmpty =
          (await ref.read(momentRepositoryProvider).getAll()).isEmpty &&
          (await ref.read(familyMemberRepositoryProvider).getAll()).isEmpty;
      final summary = await JournalBackupService().importFromFile(file.path);
      ref.invalidate(familyMembersProvider);
      ref.invalidate(ritualsProvider);
      ref.invalidate(archivedRitualsProvider);
      ref.invalidate(todayRitualsProvider);
      ref.invalidate(todayCompletedRitualIdsProvider);
      ref.invalidate(momentsProvider);
      ref.invalidate(recapProvider);
      var familyNameWarning = '';
      if (wasEmpty && ref.read(settingsProvider).familyName == 'Keluarga') {
        try {
          await ref
              .read(settingsProvider.notifier)
              .update(
                ref
                    .read(settingsProvider)
                    .copyWith(familyName: summary.familyName),
              );
        } catch (_) {
          familyNameWarning =
              ' Nama keluarga belum berubah; ubah dari Pengaturan.';
        }
      }
      if (mounted) {
        journalMessage(
          context,
          '${summary.totalAdded} catatan dipulihkan. ${summary.duplicatesSkipped} duplikat dilewati.${summary.missingPhotos > 0 ? ' ${summary.missingPhotos} foto tidak tersedia dalam cadangan.' : ''}$familyNameWarning',
        );
      }
    });
  }

  Future<void> _scrapbook() => _run('Menyusun scrapbook…', () async {
    final moments = await ref.read(momentRepositoryProvider).getAll();
    final rituals = await ref.read(ritualRepositoryProvider).getAll();
    if (moments.isEmpty && rituals.isEmpty) {
      if (mounted) {
        journalMessage(
          context,
          'Simpan satu momen atau kebiasaan sebelum membuat scrapbook.',
        );
      }
      return;
    }
    final name = ref.read(settingsProvider).familyName;
    var missingPhotos = 0;
    final file = await ScrapbookPdf().export(
      familyName: name,
      moments: moments,
      rituals: rituals,
      onMissingPhotos: (count) => missingPhotos = count,
    );
    if (!mounted) return;
    if (missingPhotos > 0 &&
        !await confirmJournalAction(
          context,
          title: '$missingPhotos foto tidak tersedia',
          message:
              'Semua cerita tetap disertakan. Foto yang hilang ditandai dalam scrapbook.',
          confirm: 'Lanjutkan ekspor',
        )) {
      return;
    }
    if (!mounted) return;
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: 'Scrapbook $name'),
    );
  });
  @override
  Widget build(BuildContext context) {
    final s = ref.watch(settingsProvider);
    final c = Theme.of(context).colorScheme;
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(title: const Text('Pengaturan')),
        body: Stack(
          children: [
            AbsorbPointer(
              absorbing: _busy,
              child: JournalPage(
                slivers: [
                  JournalBlock(
                    child: JournalHeader(
                      title: 'Nyaman untuk kalian',
                      subtitle:
                          'Atur pengingat, simpan cadangan, dan kendalikan privasi keluarga.',
                    ),
                  ),
                  JournalBlock(
                    child: EditorialCard(
                      shadow: false,
                      padding: EdgeInsets.zero,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(18),
                        leading: CircleAvatar(
                          backgroundColor: c.primaryContainer,
                          child: Icon(
                            Icons.home_outlined,
                            color: c.onPrimaryContainer,
                          ),
                        ),
                        title: Text(
                          s.familyName,
                          style: AppTheme.serif(size: 23),
                        ),
                        subtitle: const Text('Nama ruang keluarga'),
                        trailing: const Icon(Icons.edit_outlined),
                        onTap: _familyName,
                      ),
                    ),
                  ),
                  JournalBlock(
                    bottom: 12,
                    child: const JournalSection(title: 'Pengingat harian'),
                  ),
                  JournalBlock(
                    child: EditorialCard(
                      shadow: false,
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          SwitchListTile(
                            value: s.journalReminderEnabled,
                            onChanged: _reminder,
                            secondary: const Icon(Icons.notifications_outlined),
                            title: const Text('Luangkan satu menit'),
                            subtitle: const Text(
                              'Pengingat ringan untuk kebiasaan dan cerita hari ini.',
                            ),
                          ),
                          const Divider(),
                          ListTile(
                            leading: const Icon(Icons.schedule),
                            title: const Text('Waktu pengingat'),
                            subtitle: Text(
                              '${TimeOfDay(hour: s.journalReminderHour, minute: s.journalReminderMinute).format(context)} · mengikuti zona waktu perangkat',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: _time,
                          ),
                        ],
                      ),
                    ),
                  ),
                  JournalBlock(
                    bottom: 12,
                    child: const JournalSection(title: 'Tampilan'),
                  ),
                  JournalBlock(
                    child: EditorialCard(
                      shadow: false,
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          SwitchListTile(
                            value: s.darkMode,
                            onChanged: (v) => _run(
                              'Menyimpan tampilan…',
                              () => ref
                                  .read(settingsProvider.notifier)
                                  .update(
                                    ref
                                        .read(settingsProvider)
                                        .copyWith(darkMode: v),
                                  ),
                            ),
                            secondary: const Icon(Icons.dark_mode_outlined),
                            title: const Text('Mode gelap'),
                            subtitle: const Text(
                              'Warna hangat untuk suasana malam.',
                            ),
                          ),
                          const Divider(),
                          SwitchListTile(
                            value: s.reducedMotion,
                            onChanged: (v) => _run(
                              'Menyimpan tampilan…',
                              () => ref
                                  .read(settingsProvider.notifier)
                                  .update(
                                    ref
                                        .read(settingsProvider)
                                        .copyWith(reducedMotion: v),
                                  ),
                            ),
                            secondary: const Icon(Icons.animation),
                            title: const Text('Kurangi gerakan'),
                            subtitle: const Text(
                              'Batasi animasi dan transisi.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  JournalBlock(
                    bottom: 12,
                    child: const JournalSection(title: 'Catatan & cadangan'),
                  ),
                  JournalBlock(
                    child: EditorialCard(
                      shadow: false,
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _SettingRow(
                            icon: Icons.save_alt,
                            title: 'Buat cadangan',
                            subtitle:
                                'Anggota, kebiasaan, riwayat, cerita, dan foto.',
                            onTap: _backup,
                          ),
                          const Divider(),
                          _SettingRow(
                            icon: Icons.settings_backup_restore,
                            title: 'Pulihkan cadangan',
                            subtitle:
                                'Gabungkan berkas cadangan dari perangkat lain.',
                            onTap: _restore,
                          ),
                          const Divider(),
                          _SettingRow(
                            icon: Icons.picture_as_pdf_outlined,
                            title: 'Ekspor scrapbook PDF',
                            subtitle:
                                'Cerita dan foto untuk dibaca atau dicetak.',
                            onTap: _scrapbook,
                          ),
                        ],
                      ),
                    ),
                  ),
                  JournalBlock(
                    child: Text(
                      'Catatan inti tersimpan di perangkat, tanpa akun. Buat cadangan sebelum mengganti ponsel atau menghapus aplikasi. Berkas cadangan berisi data pribadi dan tidak dienkripsi; simpan di tempat yang kamu percaya.',
                      style: TextStyle(
                        color: c.onSurfaceVariant,
                        height: 1.6,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  JournalBlock(
                    bottom: 12,
                    child: const JournalSection(title: 'Dukung Arunika'),
                  ),
                  const JournalBlock(child: RemoveAdsCard()),
                  JournalBlock(
                    bottom: 12,
                    child: const JournalSection(title: 'Privasi & bantuan'),
                  ),
                  JournalBlock(
                    child: EditorialCard(
                      shadow: false,
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _SettingRow(
                            icon: Icons.privacy_tip_outlined,
                            title: 'Kebijakan privasi',
                            subtitle:
                                'Penyimpanan, iklan, pembelian, dan pilihanmu.',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const PrivacyScreen(),
                              ),
                            ),
                          ),
                          const Divider(),
                          _SettingRow(
                            icon: Icons.tune,
                            title: 'Pilihan privasi iklan',
                            subtitle:
                                'Kelola pilihan yang tersedia melalui Google.',
                            onTap: () => _run(
                              'Membuka pilihan privasi…',
                              () async {
                                try {
                                  await ref
                                      .read(monetizationProvider.notifier)
                                      .showPrivacyOptions();
                                } catch (_) {
                                  if (context.mounted) {
                                    journalMessage(
                                      context,
                                      'Pilihan privasi belum dapat dibuka. Periksa koneksi, lalu coba lagi.',
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                          const Divider(),
                          _SettingRow(
                            icon: Icons.help_outline,
                            title: 'Panduan & bantuan',
                            subtitle:
                                'Cara memakai Arunika dan menghubungi dukungan.',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const HelpScreen(),
                              ),
                            ),
                          ),
                          const Divider(),
                          _SettingRow(
                            icon: Icons.info_outline,
                            title: 'Lisensi aplikasi',
                            subtitle:
                                'Perangkat lunak yang membantu Arunika berjalan.',
                            onTap: () => showLicensePage(
                              context: context,
                              applicationName: AppIdentity.fullName,
                              applicationVersion: AppIdentity.version,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  JournalBlock(
                    child: Center(
                      child: Text(
                        '${AppIdentity.fullName}\nVersi ${AppIdentity.version}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: c.onSurfaceVariant,
                          height: 1.7,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_busy)
              Positioned.fill(
                child: ColoredBox(
                  color: c.scrim.withValues(alpha: .35),
                  child: Center(
                    child: Card(
                      margin: const EdgeInsets.all(28),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 20),
                            Text(_activity, textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
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
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
    leading: Icon(icon),
    title: Text(title),
    subtitle: Text(subtitle, style: const TextStyle(height: 1.5)),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}

class _FamilyNameDialog extends StatefulWidget {
  const _FamilyNameDialog({required this.initial});
  final String initial;
  @override
  State<_FamilyNameDialog> createState() => _FamilyNameDialogState();
}

class _FamilyNameDialogState extends State<_FamilyNameDialog> {
  late final _controller = TextEditingController(text: widget.initial);
  final _form = GlobalKey<FormState>();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Nama ruang keluarga'),
    content: Form(
      key: _form,
      child: TextFormField(
        controller: _controller,
        maxLength: 60,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        validator: (v) =>
            v == null || v.trim().isEmpty ? 'Masukkan nama keluarga.' : null,
        decoration: const InputDecoration(labelText: 'Nama keluarga'),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Batal'),
      ),
      FilledButton(
        onPressed: () {
          if (_form.currentState!.validate()) {
            Navigator.pop(context, _controller.text.trim());
          }
        },
        child: const Text('Simpan'),
      ),
    ],
  );
}
