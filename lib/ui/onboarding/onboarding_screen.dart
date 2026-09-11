import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../state/app_settings.dart';
import '../../state/together_providers.dart';
import '../navigation/main_shell.dart';
import '../settings/privacy_screen.dart';
import '../widgets/editorial_background.dart';
import '../widgets/editorial_card.dart';
import '../widgets/journal_components.dart';
import '../widgets/arunika_artwork.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _family = TextEditingController();
  final _member = TextEditingController();
  final _memberId = const Uuid().v4();
  final _form = GlobalKey<FormState>();
  bool _setup = false;
  bool _saving = false;
  bool _starter = true;
  bool _memberSaved = false;
  String? _error;
  @override
  void dispose() {
    _family.dispose();
    _member.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_saving || !(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (_member.text.trim().isNotEmpty && !_memberSaved) {
        await ref
            .read(togetherActionsProvider)
            .addMember(name: _member.text.trim(), id: _memberId);
        _memberSaved = true;
      }
      if (_starter) {
        await ref.read(togetherActionsProvider).seedStarterRituals();
      }
      final family = _family.text.trim();
      await ref
          .read(settingsProvider.notifier)
          .update(
            ref
                .read(settingsProvider)
                .copyWith(
                  familyName: family.isEmpty ? 'Keluarga' : family,
                  togetherOnboardingDone: true,
                  onboardingDone: true,
                ),
          );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const MainShell()),
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error =
              'Ruang keluarga belum selesai disimpan. Coba lagi; isianmu tetap ada.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return PopScope(
      canPop: !_setup && !_saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_saving) setState(() => _setup = false);
      },
      child: Scaffold(
        body: EditorialBackground(
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: _header(context),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        key: ValueKey(_setup),
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                        child: _setup ? _setupForm(context) : _welcome(context),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                      child: Column(
                        children: [
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                _error!,
                                style: TextStyle(color: c.error),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _saving
                                  ? null
                                  : _setup
                                  ? _finish
                                  : () => setState(() => _setup = true),
                              icon: _saving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      _setup
                                          ? Icons.check
                                          : Icons.arrow_forward,
                                    ),
                              label: Text(
                                _saving
                                    ? 'Menyiapkan ruang keluarga…'
                                    : _setup
                                    ? 'Mulai cerita keluarga'
                                    : 'Buat ruang keluarga',
                              ),
                            ),
                          ),
                          if (!_setup)
                            TextButton(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const PrivacyScreen(),
                                ),
                              ),
                              child: const Text(
                                'Tanpa akun · Pelajari privasi',
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final c = Theme.of(context).colorScheme;
      final stackProgress =
          constraints.maxWidth < 500 &&
          MediaQuery.textScalerOf(context).scale(14) > 20;
      final leading = _setup
          ? IconButton(
              tooltip: 'Kembali',
              onPressed: _saving ? null : () => setState(() => _setup = false),
              icon: const Icon(Icons.arrow_back),
            )
          : Icon(Icons.wb_sunny_outlined, color: c.tertiary, size: 30);
      final brand = Text('Arunika', style: AppTheme.serif(size: 24));
      final progress = Text(
        _setup ? '2 dari 2' : '1 dari 2',
        style: TextStyle(color: c.onSurfaceVariant, fontSize: 12),
      );
      final branding = Row(
        children: [
          leading,
          const SizedBox(width: 10),
          Expanded(child: brand),
          if (!stackProgress) ...[const SizedBox(width: 8), progress],
        ],
      );
      if (!stackProgress) return branding;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          branding,
          const SizedBox(height: 4),
          Align(alignment: Alignment.centerRight, child: progress),
        ],
      );
    },
  );

  Widget _welcome(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ArunikaArtwork(),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final compactHeadline =
                constraints.maxWidth < 500 &&
                MediaQuery.textScalerOf(context).scale(14) > 20;
            return Text(
              'Simpan yang kecil.\nIngat bersama.',
              style: AppTheme.serif(
                size: compactHeadline ? 26 : 36,
                height: 1.14,
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Text(
          'Jurnal dan kebiasaan keluarga, dalam satu tempat yang tenang.',
          style: AppTheme.sans(
            size: 16,
            height: 1.6,
            color: c.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 26),
        _promise(
          context,
          Icons.wifi_off,
          'Catat kapan saja, termasuk tanpa internet.',
        ),
        _promise(
          context,
          Icons.photo_library_outlined,
          'Cari kembali cerita dan foto favorit.',
        ),
        _promise(
          context,
          Icons.save_alt,
          'Bawa kenangan lewat cadangan dan PDF.',
        ),
      ],
    );
  }

  Widget _promise(BuildContext context, IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 23, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(height: 1.5))),
      ],
    ),
  );
  Widget _setupForm(BuildContext context) => Form(
    key: _form,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const JournalHeader(
          title: 'Untuk keluarga kalian',
          subtitle:
              'Isi sekarang atau biarkan kosong. Semuanya bisa diubah nanti.',
        ),
        const SizedBox(height: 26),
        TextFormField(
          controller: _family,
          enabled: !_saving,
          maxLength: 60,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Nama keluarga (opsional)',
            hintText: 'Contoh: Keluarga Pratama',
            prefixIcon: Icon(Icons.home_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _member,
          enabled: !_saving && !_memberSaved,
          maxLength: 60,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nama panggilan anggota (opsional)',
            hintText: 'Siapa yang ingin kamu catat ceritanya?',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 20),
        EditorialCard(
          shadow: false,
          padding: const EdgeInsets.all(4),
          child: CheckboxListTile(
            value: _starter,
            onChanged: _saving
                ? null
                : (v) => setState(() => _starter = v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('Bantu mulai dengan 3 kebiasaan'),
            subtitle: const Text(
              'Cerita sebelum tidur, berbagi rasa syukur, dan jalan akhir pekan. Bisa diubah atau diarsipkan.',
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Catatan tersimpan di perangkat ini. Buat cadangan dari Pengaturan saat ingin berpindah ponsel.',
          style: TextStyle(
            height: 1.6,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}
