import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_theme.dart';

class EditorialCard extends StatelessWidget {
  const EditorialCard({
    super.key,
    required this.child,
    this.color = AppColors.paper,
    this.gradient,
    this.padding = const EdgeInsets.all(20),
    this.borderColor = AppColors.hairline,
    this.radius = 26,
    this.onTap,
    this.semanticLabel,
    this.shadow = true,
  });

  final Widget child;
  final Color color;
  final Gradient? gradient;
  final EdgeInsetsGeometry padding;
  final Color borderColor;
  final double radius;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final card = AnimatedContainer(
      duration: AppMotion.duration(context, const Duration(milliseconds: 240)),
      curve: AppMotion.standard,
      decoration: BoxDecoration(
        color: gradient == null ? color : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
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
  const EditorialEyebrow(
    this.text, {
    super.key,
    this.color = AppColors.goldDeep,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTheme.sans(
        size: 10,
        weight: FontWeight.w800,
        color: color,
        letterSpacing: 1.6,
      ),
    );
  }
}
