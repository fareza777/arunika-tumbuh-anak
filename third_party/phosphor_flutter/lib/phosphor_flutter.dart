import 'package:flutter/material.dart';

/// A small compatibility facade for the icon API used by Arunika.
///
/// Flutter 3.44 made [IconData] final, while phosphor_flutter 2.1.0 still
/// extends it. The app only needs a focused subset of the icon catalog, so
/// these aliases keep the existing call sites stable and use the built-in
/// Material font shipped with the app.
class PhosphorIcon extends Icon {
  const PhosphorIcon(
    super.icon, {
    super.key,
    super.size,
    super.fill,
    super.weight,
    super.grade,
    super.opticalSize,
    super.color,
    super.shadows,
    super.semanticLabel,
    super.textDirection,
  });
}

class PhosphorIconsLight {
  static const arrowLeft = Icons.arrow_back;
  static const arrowRight = Icons.arrow_forward;
  static const arrowUpRight = Icons.north_east;
  static const calendarBlank = Icons.calendar_today;
  static const camera = Icons.photo_camera_outlined;
  static const caretRight = Icons.chevron_right;
  static const check = Icons.check;
  static const dotsThreeVertical = Icons.more_vert;
  static const export = Icons.ios_share;
  static const gearSix = Icons.settings_outlined;
  static const heart = Icons.favorite_border;
  static const house = Icons.home_outlined;
  static const images = Icons.photo_library_outlined;
  static const leaf = Icons.eco_outlined;
  static const listChecks = Icons.checklist;
  static const lockKey = Icons.lock_outline;
  static const pencilSimple = Icons.edit_outlined;
  static const plus = Icons.add;
  static const plusCircle = Icons.add_circle_outline;
  static const slidersHorizontal = Icons.tune;
  static const sparkle = Icons.auto_awesome;
  static const sun = Icons.wb_sunny_outlined;
  static const sunHorizon = Icons.wb_twilight;
  static const treeStructure = Icons.account_tree_outlined;
  static const user = Icons.person_outline;
  static const usersThree = Icons.groups_outlined;
  static const waveSine = Icons.waves;
  static const x = Icons.close;
}

class PhosphorIconsFill {
  static const images = Icons.photo_library;
  static const listChecks = Icons.checklist;
  static const sun = Icons.wb_sunny;
  static const treeStructure = Icons.account_tree;
}
