import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';

class SunriseProgress extends StatelessWidget {
  const SunriseProgress({super.key, required this.value, this.height = 8});

  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Container(
        height: height,
        color: AppColors.goldSoft.withValues(alpha: 0.45),
        alignment: Alignment.centerLeft,
        child: AnimatedFractionallySizedBox(
          duration: AppMotion.duration(
            context,
            const Duration(milliseconds: 500),
          ),
          curve: AppMotion.standard,
          widthFactor: value.clamp(0, 1),
          child: DecoratedBox(
            decoration: const BoxDecoration(gradient: AppColors.sunrise),
          ),
        ),
      ),
    );
  }
}
