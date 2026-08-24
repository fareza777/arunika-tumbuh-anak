import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/gold_button.dart';
import '../../state/app_settings.dart';
import '../navigation/main_shell.dart';

class _Page {
  const _Page({
    required this.title,
    required this.body,
    required this.illustration,
  });

  final String title;
  final String body;
  final _Illustration illustration;
}

enum _Illustration { chart, shield, heart }

const _pages = [
  _Page(
    title: 'Pantau Setiap\nSenti Pertumbuhannya',
    body:
        'Catat berat, tinggi, dan lingkar kepala si kecil, lalu lihat posisinya pada kurva pertumbuhan resmi — lengkap dengan grafik interaktif yang indah.',
    illustration: _Illustration.chart,
  ),
  _Page(
    title: 'Standar Resmi\nWHO & CDC',
    body:
        'Z-score dihitung dari tabel LMS asli WHO 0-5 tahun, WHO 5-19 tahun, dan CDC 2000 — dengan klasifikasi status gizi sesuai Permenkes RI.',
    illustration: _Illustration.shield,
  ),
  _Page(
    title: 'Privat, Rapi,\ndan Selalu Siap',
    body:
        'Seluruh data tersimpan aman di perangkat Anda. Lengkap dengan milestone, imunisasi, pengingat, prediksi tinggi dewasa, dan laporan PDF.',
    illustration: _Illustration.heart,
  ),
];

/// Onboarding 3 halaman dengan ilustrasi garis emas yang digambar programatik.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  var _index = 0;

  Future<void> _finish() async {
    final settings = ref.read(settingsProvider);
    await ref
        .read(settingsProvider.notifier)
        .update(settings.copyWith(onboardingDone: true));
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const MainShell()));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text('Lewati'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final page = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        const Spacer(),
                        _IllustrationCanvas(type: page.illustration),
                        const SizedBox(height: 44),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: AppTheme.serif(
                            size: 28,
                            weight: FontWeight.w600,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page.body,
                          textAlign: TextAlign.center,
                          style: AppTheme.sans(
                            size: 14,
                            color: AppColors.inkSoft,
                            height: 1.65,
                          ),
                        ),
                        const Spacer(flex: 2),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _pages.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _index ? 26 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: i == _index ? AppColors.goldGradient : null,
                      color: i == _index ? null : AppColors.hairline,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 26, 28, 26),
              child: GoldButton(
                label: isLast ? 'Mulai Sekarang' : 'Lanjut',
                icon: isLast
                    ? Icons.favorite_rounded
                    : Icons.arrow_forward_rounded,
                onPressed: () {
                  if (isLast) {
                    _finish();
                  } else {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IllustrationCanvas extends StatelessWidget {
  const _IllustrationCanvas({required this.type});

  final _Illustration type;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return CustomPaint(
          size: const Size(230, 230),
          painter: _IllustrationPainter(type: type, progress: value),
        );
      },
    );
  }
}

class _IllustrationPainter extends CustomPainter {
  _IllustrationPainter({required this.type, required this.progress});

  final _Illustration type;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);

    // Lingkaran latar lembut.
    final bgPaint = Paint()..color = AppColors.goldMist;
    canvas.drawCircle(center, 105, bgPaint);
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = AppColors.goldSoft;
    canvas.drawCircle(center, 105, ringPaint);

    final gold = Paint()
      ..color = AppColors.goldDeep
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    switch (type) {
      case _Illustration.chart:
        _paintChart(canvas, size, gold);
      case _Illustration.shield:
        _paintShield(canvas, size, gold);
      case _Illustration.heart:
        _paintHeart(canvas, size, gold);
    }
  }

  void _paintChart(Canvas canvas, Size size, Paint gold) {
    final origin = Offset(size.width * 0.22, size.height * 0.72);
    final end = Offset(size.width * 0.78, size.height * 0.72);
    final top = Offset(size.width * 0.22, size.height * 0.28);

    // Sumbu.
    canvas.drawLine(origin, end, gold..strokeWidth = 2.4);
    canvas.drawLine(origin, top, gold);

    // Kurva pertumbuhan.
    final path = Path()
      ..moveTo(size.width * 0.26, size.height * 0.66)
      ..cubicTo(
        size.width * 0.42,
        size.height * 0.60,
        size.width * 0.55,
        size.height * 0.46,
        size.width * 0.74,
        size.height * 0.34,
      );
    final curvePaint = Paint()
      ..color = AppColors.gold
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * progress),
      curvePaint,
    );

    // Titik data.
    final dotPaint = Paint()..color = AppColors.goldDeep;
    for (final t in [0.15, 0.45, 0.75, 1.0]) {
      if (t > progress) break;
      final pos = metric.getTangentForOffset(metric.length * t)!.position;
      canvas.drawCircle(pos, 5, dotPaint);
      canvas.drawCircle(pos, 8.5, Paint()..color = AppColors.goldSoft);
    }
  }

  void _paintShield(Canvas canvas, Size size, Paint gold) {
    final cx = size.width / 2;
    final path = Path()
      ..moveTo(cx, size.height * 0.24)
      ..quadraticBezierTo(
        size.width * 0.72,
        size.height * 0.30,
        size.width * 0.72,
        size.height * 0.38,
      )
      ..quadraticBezierTo(
        size.width * 0.72,
        size.height * 0.62,
        cx,
        size.height * 0.76,
      )
      ..quadraticBezierTo(
        size.width * 0.28,
        size.height * 0.62,
        size.width * 0.28,
        size.height * 0.38,
      )
      ..quadraticBezierTo(
        size.width * 0.28,
        size.height * 0.30,
        cx,
        size.height * 0.24,
      )
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.goldSoft.withValues(alpha: 0.5)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(path, gold..strokeWidth = 3);

    // Centang.
    final check = Path()
      ..moveTo(cx - 26, size.height * 0.47)
      ..lineTo(cx - 6, size.height * 0.56)
      ..lineTo(cx + 30, size.height * 0.36);
    final checkPaint = Paint()
      ..color = AppColors.goldDeep
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final metric = check.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * progress),
      checkPaint,
    );
  }

  void _paintHeart(Canvas canvas, Size size, Paint gold) {
    final cx = size.width / 2;
    final cy = size.height * 0.46;
    final s = 44.0;

    final path = Path()
      ..moveTo(cx, cy + s * 0.9)
      ..cubicTo(
        cx - s * 1.6,
        cy,
        cx - s * 0.9,
        cy - s * 1.15,
        cx,
        cy - s * 0.35,
      )
      ..cubicTo(
        cx + s * 0.9,
        cy - s * 1.15,
        cx + s * 1.6,
        cy,
        cx,
        cy + s * 0.9,
      );

    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.girlSoft
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(path, gold..strokeWidth = 3);

    // Rumah kecil di bawah hati (simbol data di perangkat/rumah).
    final homeY = size.height * 0.70;
    final home = Path()
      ..moveTo(cx - 20, homeY)
      ..lineTo(cx - 20, homeY + 18)
      ..lineTo(cx + 20, homeY + 18)
      ..lineTo(cx + 20, homeY)
      ..close();
    canvas.drawPath(home, gold..strokeWidth = 2.6);
    canvas.drawLine(Offset(cx - 26, homeY), Offset(cx, homeY - 16), gold);
    canvas.drawLine(Offset(cx + 26, homeY), Offset(cx, homeY - 16), gold);

    // Sinar kecil di sekitar hati.
    final rayPaint = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.8 * progress)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (final angle in [-0.5, 0.0, 0.5]) {
      final a = -math.pi / 2 + angle;
      final start = Offset(cx + 62 * math.cos(a), cy + 62 * math.sin(a));
      final end = Offset(cx + 74 * math.cos(a), cy + 74 * math.sin(a));
      canvas.drawLine(start, end, rayPaint);
    }
  }

  @override
  bool shouldRepaint(_IllustrationPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.type != type;
}
