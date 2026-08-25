import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../app.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/family_member.dart';
import '../../domain/together/scrapbook_pdf.dart';
import '../../state/app_settings.dart';
import '../../state/monetization_provider.dart';
import '../../state/together_providers.dart';
import '../monetization/remove_ads_card.dart';
import '../together/family_member_editor_sheet.dart';
import '../widgets/editorial_background.dart';
import '../widgets/editorial_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final members = ref.watch(familyMembersProvider);
    return Scaffold(
      body: EditorialBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 38),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Kembali',
                    icon: const PhosphorIcon(PhosphorIconsLight.arrowLeft),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Pengaturan',
                    style: AppTheme.serif(size: 25, weight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              EditorialCard(
                gradient: AppColors.sunrise,
                shadow: false,
                onTap: () => _editFamilyName(context, ref, settings),
                semanticLabel: 'Edit nama ruang keluarga',
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.paper,
                      ),
                      child: const PhosphorIcon(
                        PhosphorIconsLight.sun,
                        size: 28,
                        color: AppColors.goldDeep,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RUANG KALIAN',
                            style: AppTheme.sans(
                              size: 9.5,
                              weight: FontWeight.w800,
                              color: AppColors.espresso,
                              letterSpacing: 1.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            settings.familyName,
                            style: AppTheme.serif(
                              size: 22,
                              weight: FontWeight.w600,
                              color: AppColors.espresso,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Ketuk untuk mengganti nama',
                            style: AppTheme.sans(
                              size: 10.5,
                              color: AppColors.espresso.withValues(alpha: 0.68),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PhosphorIcon(
                      PhosphorIconsLight.pencilSimple,
                      color: AppColors.espresso,
                      size: 20,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const _SectionLabel('ORANG-ORANG DI SINI'),
              const SizedBox(height: 10),
              members.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (_, _) => const EditorialCard(
                  child: Text('Daftar anggota belum dapat dimuat.'),
                ),
                data: (items) => Column(
                  children: [
                    for (final member in items) ...[
                      _MemberSettingRow(
                        member: member,
                        onTap: () => _editMember(context, member),
                      ),
                      const SizedBox(height: 8),
                    ],
                    _AddMemberRow(onTap: () => _editMember(context, null)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const _SectionLabel('PRIVASI & KENYAMANAN'),
              const SizedBox(height: 10),
              EditorialCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    const ListTile(
                      leading: PhosphorIcon(
                        PhosphorIconsLight.lockKey,
                        color: AppColors.sageDeep,
                      ),
                      title: Text('Lokal secara default'),
                      subtitle: Text(
                        'Cerita, ritual, dan foto tersimpan di perangkat ini.',
                        style: TextStyle(height: 1.35),
                      ),
                    ),
                    const Divider(height: 1),
                    SwitchListTile.adaptive(
                      value: settings.reducedMotion,
                      onChanged: (value) => ref
                          .read(settingsProvider.notifier)
                          .update(settings.copyWith(reducedMotion: value)),
                      secondary: const PhosphorIcon(
                        PhosphorIconsLight.waveSine,
                        color: AppColors.sageDeep,
                      ),
                      title: const Text('Kurangi gerakan'),
                      subtitle: const Text(
                        'Gunakan transisi yang lebih tenang.',
                        style: TextStyle(height: 1.35),
                      ),
                    ),
                    const Divider(height: 1),
                    SwitchListTile.adaptive(
                      value: settings.darkMode,
                      onChanged: (value) => ref
                          .read(settingsProvider.notifier)
                          .update(settings.copyWith(darkMode: value)),
                      secondary: const Icon(Icons.dark_mode_outlined),
                      title: const Text('Mode gelap'),
                      subtitle: const Text(
                        'Gunakan palet malam Arunika yang lebih nyaman.',
                        style: TextStyle(height: 1.35),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const PhosphorIcon(
                        PhosphorIconsLight.export,
                        color: AppColors.sageDeep,
                      ),
                      title: const Text('Ekspor scrapbook'),
                      subtitle: const Text(
                        'Bawa cerita kalian menjadi PDF.',
                        style: TextStyle(height: 1.35),
                      ),
                      trailing: const PhosphorIcon(
                        PhosphorIconsLight.caretRight,
                        size: 18,
                      ),
                      onTap: () =>
                          _exportScrapbook(context, ref, settings.familyName),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const _SectionLabel('DUKUNG ARUNIKA'),
              const SizedBox(height: 10),
              const RemoveAdsCard(),
              const SizedBox(height: 6),
              TextButton.icon(
                onPressed: () => ref
                    .read(monetizationProvider.notifier)
                    .showPrivacyOptions(),
                icon: const PhosphorIcon(
                  PhosphorIconsLight.slidersHorizontal,
                  size: 18,
                ),
                label: const Text('Kelola opsi privasi iklan'),
              ),
              const SizedBox(height: 20),
              const _SectionLabel('TENTANG'),
              const SizedBox(height: 10),
              EditorialCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.sunrise,
                          ),
                          child: const PhosphorIcon(
                            PhosphorIconsLight.sun,
                            color: AppColors.espresso,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppIdentity.fullName,
                              style: TextStyle(
                                fontFamily: 'Fraunces',
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink,
                              ),
                            ),
                            Text(
                              'Versi ${AppIdentity.version}',
                              style: TextStyle(
                                fontFamily: 'PlusJakartaSans',
                                fontSize: 11,
                                color: AppColors.inkFaint,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Arunika dibuat untuk keluarga yang ingin mengingat proses, bukan mengejar kesempurnaan.',
                      style: AppTheme.sans(
                        size: 12,
                        color: AppColors.inkSoft,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Kebijakan privasi tersedia dari halaman Play Store dan menjelaskan penyimpanan lokal, lampiran foto, iklan, serta pembelian.',
                      style: AppTheme.sans(
                        size: 11,
                        color: AppColors.inkFaint,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editFamilyName(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) async {
    final controller = TextEditingController(text: settings.familyName);
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nama ruang keluarga'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Contoh: Rumah Arunika'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null && value.isNotEmpty) {
      await ref
          .read(settingsProvider.notifier)
          .update(settings.copyWith(familyName: value));
    }
  }

  Future<void> _editMember(BuildContext context, FamilyMember? member) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => FamilyMemberEditorSheet(initial: member),
    );
  }

  Future<void> _exportScrapbook(
    BuildContext context,
    WidgetRef ref,
    String familyName,
  ) async {
    try {
      final moments = await ref.read(momentsProvider.future);
      final rituals = await ref.read(ritualsProvider.future);
      final file = await ScrapbookPdf().export(
        familyName: familyName,
        moments: moments,
        rituals: rituals,
      );
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'Scrapbook $familyName — Arunika',
        ),
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scrapbook belum dapat dibuat: $error')),
        );
      }
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: AppTheme.sans(
      size: 10,
      weight: FontWeight.w800,
      color: AppColors.terracottaDeep,
      letterSpacing: 1.5,
    ),
  );
}

class _MemberSettingRow extends StatelessWidget {
  const _MemberSettingRow({required this.member, required this.onTap});

  final FamilyMember member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => EditorialCard(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    onTap: onTap,
    semanticLabel: 'Edit anggota ${member.name}',
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.goldMist,
          ),
          child: Center(
            child: Text(
              member.name.characters.first.toUpperCase(),
              style: AppTheme.serif(
                size: 16,
                weight: FontWeight.w600,
                color: AppColors.goldDeep,
              ),
            ),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                member.name,
                style: AppTheme.sans(size: 13, weight: FontWeight.w800),
              ),
              Text(
                member.roleLabel,
                style: AppTheme.sans(size: 10.5, color: AppColors.inkFaint),
              ),
            ],
          ),
        ),
        const PhosphorIcon(
          PhosphorIconsLight.pencilSimple,
          size: 18,
          color: AppColors.inkFaint,
        ),
      ],
    ),
  );
}

class _AddMemberRow extends StatelessWidget {
  const _AddMemberRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => EditorialCard(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    color: AppColors.sageMist,
    shadow: false,
    onTap: onTap,
    semanticLabel: 'Tambah anggota keluarga',
    child: Row(
      children: [
        const PhosphorIcon(
          PhosphorIconsLight.plusCircle,
          color: AppColors.sageDeep,
        ),
        const SizedBox(width: 11),
        Text(
          'Tambah orang yang ingin dirayakan',
          style: AppTheme.sans(
            size: 12.5,
            weight: FontWeight.w800,
            color: AppColors.sageDeep,
          ),
        ),
      ],
    ),
  );
}
