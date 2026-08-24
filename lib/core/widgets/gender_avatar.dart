import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Avatar anak dengan cincin gradien sesuai jenis kelamin.
class GenderAvatar extends StatelessWidget {
  const GenderAvatar({
    super.key,
    required this.name,
    required this.isBoy,
    this.photoPath,
    this.size = 56,
    this.ringWidth = 2.5,
    this.showRing = true,
  });

  final String name;
  final bool isBoy;
  final String? photoPath;
  final double size;
  final double ringWidth;
  final bool showRing;

  @override
  Widget build(BuildContext context) {
    final hasPhoto =
        photoPath != null &&
        photoPath!.isNotEmpty &&
        File(photoPath!).existsSync();

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(showRing ? ringWidth : 0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: showRing ? AppColors.genderGradient(isBoy) : null,
        color: showRing ? null : AppColors.forGenderSoft(isBoy),
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.forGenderSoft(isBoy),
          border: showRing
              ? Border.all(color: AppColors.surface, width: 2)
              : null,
          image: hasPhoto
              ? DecorationImage(
                  image: FileImage(File(photoPath!)),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        alignment: Alignment.center,
        child: hasPhoto
            ? null
            : Text(
                _initial(name),
                style: AppTheme.serif(
                  size: size * 0.38,
                  weight: FontWeight.w600,
                  color: AppColors.forGenderDeep(isBoy),
                ),
              ),
      ),
    );
  }

  String _initial(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.characters.first.toUpperCase();
  }
}
