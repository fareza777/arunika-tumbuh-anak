import 'package:flutter/material.dart';

/// Animasi masuk "fade + naik" dengan jeda opsional.
/// Dipakai berjenjang untuk menciptakan kesan layar yang hidup.
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 550),
    this.offset = 18,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offset;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration + delay,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final t = _delayed(value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, offset * (1 - t)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  double _delayed(double raw) {
    final total = duration + delay;
    final delayFraction = delay.inMilliseconds / total.inMilliseconds;
    if (raw <= delayFraction) return 0;
    final t = (raw - delayFraction) / (1 - delayFraction);
    return Curves.easeOutCubic.transform(t.clamp(0.0, 1.0));
  }
}

/// Penomoran berjenjang untuk daftar.
class StaggeredColumn extends StatelessWidget {
  const StaggeredColumn({
    super.key,
    required this.children,
    this.baseDelay = 60,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
  });

  final List<Widget> children;
  final int baseDelay;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        for (var i = 0; i < children.length; i++)
          FadeSlideIn(
            delay: Duration(milliseconds: baseDelay * i),
            child: children[i],
          ),
      ],
    );
  }
}
