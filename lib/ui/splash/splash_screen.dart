import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app.dart';
import '../../core/theme/app_theme.dart';
import '../../state/app_settings.dart';
import '../../state/together_providers.dart';
import '../navigation/main_shell.dart';
import '../onboarding/onboarding_screen.dart';
import '../widgets/editorial_background.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  String? _error;
  bool _loading = false;
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      ref.invalidate(familyMembersProvider);
      ref.invalidate(ritualsProvider);
      ref.invalidate(momentsProvider);
      await Future.wait([
        ref.read(familyMembersProvider.future),
        ref.read(ritualsProvider.future),
        ref.read(momentsProvider.future),
      ]).timeout(const Duration(seconds: 15));
      if (!mounted) return;
      final done = ref.read(settingsProvider).togetherOnboardingDone;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => done ? const MainShell() : const OnboardingScreen(),
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error =
              'Catatan belum dapat dibuka. Periksa ruang penyimpanan perangkat, lalu coba lagi.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Scaffold(
      body: EditorialBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c.tertiaryContainer,
                    ),
                    child: Icon(
                      Icons.wb_sunny_outlined,
                      size: 54,
                      color: c.onTertiaryContainer,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(AppIdentity.name, style: AppTheme.serif(size: 42)),
                  const SizedBox(height: 8),
                  Text(
                    AppIdentity.tagline,
                    style: TextStyle(color: c.onSurfaceVariant, fontSize: 16),
                  ),
                  const SizedBox(height: 40),
                  if (_error == null) ...[
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(height: 16),
                    const Text('Membuka catatan keluarga…'),
                  ] else ...[
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: c.error, height: 1.6),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _bootstrap,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba lagi'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
