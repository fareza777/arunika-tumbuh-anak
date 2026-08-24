import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/moment.dart';

class MomentTagChip extends StatelessWidget {
  const MomentTagChip({
    super.key,
    required this.tag,
    this.selected = false,
    this.onTap,
  });

  final MomentTag tag;
  final bool selected;
  final VoidCallback? onTap;

  Color get _accent {
    switch (tag) {
      case MomentTag.laugh:
        return AppColors.terracotta;
      case MomentTag.learn:
        return AppColors.sageDeep;
      case MomentTag.together:
        return AppColors.goldDeep;
      case MomentTag.brave:
        return AppColors.info;
      case MomentTag.gratitude:
        return AppColors.girlDeep;
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: selected ? _accent.withValues(alpha: 0.14) : AppColors.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: selected ? _accent : AppColors.hairline),
      ),
      child: Text(
        tag.label,
        style: AppTheme.sans(
          size: 12,
          weight: FontWeight.w700,
          color: selected ? _accent : AppColors.inkSoft,
        ),
      ),
    );
    return Semantics(
      button: onTap != null,
      selected: selected,
      label: 'Tag ${tag.label}',
      child: onTap == null
          ? content
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: content,
            ),
    );
  }
}
