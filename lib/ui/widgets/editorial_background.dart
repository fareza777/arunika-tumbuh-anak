import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class EditorialBackground extends StatelessWidget {
  const EditorialBackground({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(color: theme.scaffoldBackgroundColor),
      child: Stack(
        children: [
          const Positioned.fill(child: IgnorePointer(child: _PaperTexture())),
          Padding(padding: padding ?? EdgeInsets.zero, child: child),
        ],
      ),
    );
  }
}

class _PaperTexture extends StatelessWidget {
  const _PaperTexture();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _PaperTexturePainter());
  }
}

class _PaperTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.goldSoft.withValues(alpha: 0.13);
    final center = Offset(size.width * 0.86, size.height * 0.07);
    canvas.drawCircle(center, size.width * 0.34, paint);
    final line = Paint()
      ..color = AppColors.terracotta.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path();
    for (var i = 0; i < 3; i++) {
      final y = size.height * (0.84 + i * 0.025);
      path.moveTo(0, y);
      path.cubicTo(
        size.width * 0.28,
        y - 12,
        size.width * 0.65,
        y + 12,
        size.width,
        y - 3,
      );
    }
    canvas.drawPath(path, line);
    final rays = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.17)
      ..strokeWidth = 1.2;
    for (var i = 0; i < 7; i++) {
      final angle = -math.pi * 0.82 + (math.pi * 0.64 * i / 6);
      final start = Offset(
        center.dx + math.cos(angle) * size.width * 0.22,
        center.dy + math.sin(angle) * size.width * 0.22,
      );
      final end = Offset(
        center.dx + math.cos(angle) * size.width * 0.30,
        center.dy + math.sin(angle) * size.width * 0.30,
      );
      canvas.drawLine(start, end, rays);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
