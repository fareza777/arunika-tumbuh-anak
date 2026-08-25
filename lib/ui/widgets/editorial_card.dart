import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_theme.dart';

class EditorialCard extends StatelessWidget {
  const EditorialCard({
    super.key,
    required this.child,
    this.color,
    this.gradient,
    this.padding = const EdgeInsets.all(20),
    this.borderColor,
    this.radius = 26,
    this.onTap,
    this.semanticLabel,
    this.shadow = true,
  });

  final Widget child;
  final Color? color;
  final Gradient? gradient;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final double radius;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = color ?? theme.cardColor;
    final cardBorder = borderColor ?? theme.colorScheme.outline;
    final card = AnimatedContainer(
      duration: AppMotion.duration(context, const Duration(milliseconds: 240)),
      curve: AppMotion.standard,
      decoration: BoxDecoration(
        color: gradient == null ? cardColor : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: cardBorder),
        boxShadow: shadow
            ? AppColors.softShadow(opacity: 0.055, blur: 22, y: 8)
            : null,
      ),
      child: Padding(padding: padding, child: child),
    );

    final tappable = onTap == null
        ? card
        : Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(radius),
              child: card,
            ),
          );
    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      child: tappable,
    );
  }
}

class EditorialEyebrow extends StatelessWidget {
  const EditorialEyebrow(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? Theme.of(context).colorScheme.primary;
    return Text(
      text.toUpperCase(),
      style: AppTheme.sans(
        size: 10,
        weight: FontWeight.w800,
        color: resolvedColor,
        letterSpacing: 1.6,
      ),
    );
  }
}
