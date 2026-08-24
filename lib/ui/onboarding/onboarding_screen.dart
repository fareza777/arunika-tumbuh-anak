import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_theme.dart';
import '../../state/app_settings.dart';
import '../../state/together_providers.dart';
import '../navigation/main_shell.dart';
import '../widgets/editorial_background.dart';
import '../widgets/editorial_card.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  final _familyController = TextEditingController(text: 'Keluarga');
  final _memberController = TextEditingController();
  var _index = 0;
  var _saving = false;

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);
    final familyName = _familyController.text.trim().isEmpty
        ? 'Keluarga'
        : _familyController.text.trim();
    final settings = ref.read(settingsProvider);
    await ref
        .read(settingsProvider.notifier)
        .update(
          settings.copyWith(
            onboardingDone: true,
            togetherOnboardingDone: true,
            familyName: familyName,
          ),
        );
    final memberName = _memberController.text.trim();
    if (memberName.isNotEmpty) {
      await ref.read(togetherActionsProvider).addMember(name: memberName);
    }
    await ref.read(togetherActionsProvider).seedStarterRituals();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: AppMotion.duration(
          context,
          const Duration(milliseconds: 500),
        ),
        pageBuilder: (_, _, _) => const MainShell(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  void _next() {
    if (_index == 2) {
      _finish();
      return;
    }
    _pageController.nextPage(
      duration: AppMotion.duration(context, const Duration(milliseconds: 420)),
      curve: AppMotion.standard,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _familyController.dispose();
    _memberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: EditorialBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 18, 0),
                child: Row(
                  children: [
                    const _BrandMark(),
                    const Spacer(),
                    TextButton(
                      onPressed: _saving ? null : _finish,
                      child: const Text('Lewati'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (value) => setState(() => _index = value),
                  children: [
                    const _IntroPage(
                      icon: PhosphorIconsLight.sunHorizon,
                      eyebrow: 'SELAMAT DATANG DI RUMAH',
                      title: 'Yang kecil hari ini,\nbesar nanti.',
                      body:
                          'Arunika membantu keluarga menyimpan cerita, merayakan kebiasaan kecil, dan melihat hari-hari bersama dengan lebih sadar.',
                      accent: AppColors.gold,
                    ),
                    const _IntroPage(
                      icon: PhosphorIconsLight.sparkle,
                      eyebrow: 'RITUAL, BUKAN TARGET',
                      title: 'Kebersamaan tidak\nperlu sempurna.',
                      body:
                          'Pilih satu jeda yang terasa milik kalian. Ulangi saat sempat. Setiap tanda hadir adalah benang baru di Taman Arunika.',
                      accent: AppColors.sageDeep,
                    ),
                    _SetupPage(
                      familyController: _familyController,
                      memberController: _memberController,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        3,
                        (i) => AnimatedContainer(
                          duration: AppMotion.duration(
                            context,
                            const Duration(milliseconds: 260),
                          ),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == _index ? 30 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _index
                                ? AppColors.terracotta
                                : AppColors.goldSoft,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _next,
                        icon: const PhosphorIcon(
                          PhosphorIconsLight.arrowRight,
                          size: 20,
                        ),
                        label: Text(
                          _index == 2 ? 'Masuk ke Arunika' : 'Lanjut',
                        ),
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
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.sunrise,
          ),
          child: const PhosphorIcon(
            PhosphorIconsLight.sun,
            size: 19,
            color: AppColors.espresso,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'ARUNIKA',
          style: AppTheme.sans(
            size: 11,
            weight: FontWeight.w800,
            letterSpacing: 2.1,
          ),
        ),
      ],
    );
  }
}

class _IntroPage extends StatelessWidget {
  const _IntroPage({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.accent,
  });

  final IconData icon;
  final String eyebrow;
  final String title;
  final String body;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 34, 30, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 188,
              height: 188,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.13),
                border: Border.all(color: accent.withValues(alpha: 0.35)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 122,
                    height: 122,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.paper.withValues(alpha: 0.88),
                      boxShadow: AppColors.softShadow(
                        opacity: 0.08,
                        blur: 22,
                        y: 8,
                      ),
                    ),
                  ),
                  PhosphorIcon(icon, size: 58, color: accent),
                  Positioned(
                    right: 20,
                    top: 30,
                    child: Icon(
                      Icons.circle,
                      size: 8,
                      color: accent.withValues(alpha: 0.65),
                    ),
                  ),
                  Positioned(
                    left: 25,
                    bottom: 34,
                    child: Icon(
                      Icons.circle,
                      size: 5,
                      color: accent.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          EditorialEyebrow(eyebrow, color: accent),
          const SizedBox(height: 14),
          Text(
            title,
            style: AppTheme.serif(
              size: 37,
              weight: FontWeight.w600,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            body,
            style: AppTheme.sans(
              size: 15,
              color: AppColors.inkSoft,
              height: 1.65,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SetupPage extends StatelessWidget {
  const _SetupPage({
    required this.familyController,
    required this.memberController,
  });

  final TextEditingController familyController;
  final TextEditingController memberController;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(30, 34, 30, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          EditorialCard(
            color: AppColors.sunrise.colors.first.withValues(alpha: 0.9),
            shadow: false,
            child: const Row(
              children: [
                PhosphorIcon(
                  PhosphorIconsLight.heart,
                  size: 32,
                  color: AppColors.espresso,
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Buat ruang kecil untuk cerita kalian.',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontWeight: FontWeight.w700,
                      color: AppColors.espresso,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 34),
          const EditorialEyebrow('SATU MENIT UNTUK MULAI'),
          const SizedBox(height: 14),
          Text(
            'Siapa yang tinggal\ndi ruang ini?',
            style: AppTheme.serif(
              size: 36,
              weight: FontWeight.w600,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Nama ruang dan satu nama anggota sudah cukup. Semua bisa diubah nanti.',
            style: AppTheme.sans(
              size: 14,
              color: AppColors.inkSoft,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 26),
          TextField(
            controller: familyController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Nama ruang keluarga',
              prefixIcon: PhosphorIcon(PhosphorIconsLight.house),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: memberController,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Nama anggota (opsional)',
              prefixIcon: PhosphorIcon(PhosphorIconsLight.user),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Disimpan lokal di perangkat ini. Tidak perlu akun.',
            style: AppTheme.sans(
              size: 11.5,
              color: AppColors.inkFaint,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
