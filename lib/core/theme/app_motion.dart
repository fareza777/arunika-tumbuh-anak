import 'package:flutter/material.dart';

class AppMotion {
  AppMotion._();

  static Duration duration(BuildContext context, Duration normal) {
    final media = MediaQuery.maybeOf(context);
    return media?.disableAnimations == true ? Duration.zero : normal;
  }

  static Curve get standard => Curves.easeOutCubic;
  static Curve get spring => Curves.easeOutBack;
}
