import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppGradients {
  AppGradients._();

  static const LinearGradient sunrise = AppColors.sunrise;
  static const LinearGradient sage = AppColors.sageGradient;

  static LinearGradient soft(Color color) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [color.withValues(alpha: 0.18), color.withValues(alpha: 0.04)],
  );
}
