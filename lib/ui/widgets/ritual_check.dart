import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';

class RitualCheck extends StatelessWidget {
  const RitualCheck({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 54,
    this.label = 'Tandai ritual selesai',
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final double size;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      checked: value,
      button: true,
      child: InkResponse(
        onTap: () => onChanged(!value),
        radius: size * 0.7,
        child: AnimatedContainer(
          duration: AppMotion.duration(
            context,
            const Duration(milliseconds: 280),
          ),
          curve: AppMotion.spring,
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: value ? AppColors.sageGradient : null,
            color: value ? null : AppColors.ivory,
            border: Border.all(
              color: value ? AppColors.sageDeep : AppColors.goldSoft,
              width: value ? 0 : 1.6,
            ),
            boxShadow: value
                ? AppColors.softShadow(opacity: 0.11, blur: 14, y: 5)
                : null,
          ),
          child: PhosphorIcon(
            value ? PhosphorIconsLight.check : PhosphorIconsLight.plus,
            size: size * 0.42,
            color: value ? Colors.white : AppColors.goldDeep,
          ),
        ),
      ),
    );
  }
}
