import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../state/app_settings.dart';
import '../../state/together_providers.dart';
import '../navigation/main_shell.dart';
import '../onboarding/onboarding_screen.dart';

/// Splash screen matahari terbit emas (nama "Arunika" = cahaya pagi),
/// sambil memuat ruang keluarga, ritual, dan momen lokal.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final results = await Future.wait([
      ref.read(familyMembersProvider.future),
      ref.read(ritualsProvider.future),
      ref.read(momentsProvider.future),
      Future<void>.delayed(const Duration(milliseconds: 2100)),
    ]).catchError((_) => <Object?>[]);
    results; // data sudah tercache di provider

    if (!mounted) return;
    final onboardingDone = ref.read(settingsProvider).togetherOnboardingDone;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, _, _) =>
            onboardingDone ? const MainShell() : const OnboardingScreen(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(180, 120),
                  painter: _SunrisePainter(progress: _controller.value),
                );
              },
            ),
            const SizedBox(height: 8),
            FadeSlideDelayed(
              delay: 500,
              child: Text(
                AppIdentity.name,
                style: AppTheme.serif(
                  size: 42,
                  weight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 6),
            FadeSlideDelayed(
              delay: 750,
              child: Text(
                AppIdentity.tagline.toUpperCase(),
                style: AppTheme.sans(
                  size: 12,
                  weight: FontWeight.w700,
                  color: AppColors.goldDeep,
                  letterSpacing: 3.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FadeSlideDelayed extends StatelessWidget {
  const FadeSlideDelayed({super.key, required this.delay, required this.child});

  final int delay;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 900 + delay),
      builder: (context, value, child) {
        final t = ((value * (900 + delay) - delay) / 900).clamp(0.0, 1.0);
        final eased = Curves.easeOutCubic.transform(t);
        return Opacity(
          opacity: eased,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - eased)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Matahari terbit: garis horizon + setengah lingkaran emas + sinar.
class _SunrisePainter extends CustomPainter {
  _SunrisePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final horizonY = size.height * 0.78;
    final eased = Curves.easeOutCubic.transform(progress);

    // Matahari naik dari balik horizon.
    final sunRadius = 34.0;
    final sunY = horizonY + 10 - (44 * eased);

    final sunPaint = Paint()
      ..shader =
          const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEAC97E), AppColors.gold],
          ).createShader(
            Rect.fromCircle(center: Offset(centerX, sunY), radius: sunRadius),
          );
    canvas.drawCircle(Offset(centerX, sunY), sunRadius, sunPaint);

    // Sinar matahari.
    final rayPaint = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.75 * eased)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 7; i++) {
      final angle = math.pi + (math.pi * i / 6);
      final inner = sunRadius + 9;
      final outer = sunRadius + 9 + 13 * eased;
      canvas.drawLine(
        Offset(
          centerX + inner * math.cos(angle),
          sunY + inner * math.sin(angle),
        ),
        Offset(
          centerX + outer * math.cos(angle),
          sunY + outer * math.sin(angle),
        ),
        rayPaint,
      );
    }

    // Garis horizon.
    final horizonPaint = Paint()
      ..color = AppColors.goldDeep.withValues(alpha: 0.85)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final lineWidth = size.width * 0.82 * eased;
    canvas.drawLine(
      Offset(centerX - lineWidth / 2, horizonY),
      Offset(centerX + lineWidth / 2, horizonY),
      horizonPaint,
    );
  }

  @override
  bool shouldRepaint(_SunrisePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
