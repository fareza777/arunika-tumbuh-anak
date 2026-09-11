import 'package:flutter/material.dart';

/// Original editorial artwork, bundled for the offline first-run experience.
class ArunikaArtwork extends StatelessWidget {
  const ArunikaArtwork({super.key});
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(26),
    child: Image.asset(
      'assets/illustrations/family-reading.png',
      fit: BoxFit.cover,
      cacheWidth: 1000,
      semanticLabel: 'Ilustrasi keluarga membaca buku bersama di rumah',
      width: double.infinity,
      gaplessPlayback: true,
    ),
  );
}
