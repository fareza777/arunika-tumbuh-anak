import 'package:flutter/material.dart';

/// Palet warna "Arunika Light Luxury".
/// Hangat, cerah, dan elegan — dirancang untuk para ibu:
/// ivory lembut, aksen champagne-gold, dan status gizi yang mudah dibaca.
class AppColors {
  AppColors._();

  // ── Dasar ──────────────────────────────────────────────────────────────
  static const Color ivory = Color(0xFFFBF7EF);
  static const Color pearl = Color(0xFFFDFBF6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cream = Color(0xFFF4EDDE);

  // ── Tinta (teks) ───────────────────────────────────────────────────────
  static const Color ink = Color(0xFF2D2820);
  static const Color inkSoft = Color(0xFF7C7162);
  static const Color inkFaint = Color(0xFFB0A591);

  // ── Garis halus ────────────────────────────────────────────────────────
  static const Color hairline = Color(0xFFEBE2D1);

  // ── Emas champagne (brand) ─────────────────────────────────────────────
  static const Color gold = Color(0xFFC29A3C);
  // Digelapkan demi kontras WCAG AA untuk teks kecil di atas ivory.
  static const Color goldDeep = Color(0xFF7E6220);
  static const Color goldSoft = Color(0xFFEBDCAF);
  static const Color goldMist = Color(0xFFF8F1DE);

  // ── Aksen jenis kelamin ────────────────────────────────────────────────
  static const Color boy = Color(0xFF5E9CC6);
  static const Color boyDeep = Color(0xFF3E7CA8);
  static const Color boySoft = Color(0xFFE4F0F8);

  static const Color girl = Color(0xFFDE8FA3);
  static const Color girlDeep = Color(0xFFC06B83);
  static const Color girlSoft = Color(0xFFFAE9EE);

  // ── Status gizi ────────────────────────────────────────────────────────
  static const Color good = Color(0xFF5F9B77);
  static const Color goodSoft = Color(0xFFE3F1E8);

  static const Color warn = Color(0xFFD9A13F);
  static const Color warnSoft = Color(0xFFFAF0DC);

  static const Color danger = Color(0xFFCF6656);
  static const Color dangerSoft = Color(0xFFF9E4E0);

  static const Color info = Color(0xFF6E8FB8);
  static const Color infoSoft = Color(0xFFE6EDF6);

  // ── Gradien khas ───────────────────────────────────────────────────────
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD9B45C), Color(0xFFC29A3C), Color(0xFFA8842E)],
  );

  static const LinearGradient goldSheen = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF3E5BC), Color(0xFFE3CE93)],
  );

  static const LinearGradient boyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7FB6DB), Color(0xFF5E9CC6)],
  );

  static const LinearGradient girlGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFECA9BA), Color(0xFFDE8FA3)],
  );

  // ── Bayangan lembut khas "light luxury" ────────────────────────────────
  static List<BoxShadow> softShadow({
    double opacity = 0.08,
    double blur = 24,
    double y = 10,
  }) {
    return [
      BoxShadow(
        color: const Color(0xFF8A7A58).withValues(alpha: opacity),
        blurRadius: blur,
        offset: Offset(0, y),
      ),
    ];
  }

  static List<BoxShadow> cardShadow = softShadow();

  /// Warna aksen berdasarkan jenis kelamin.
  static Color forGender(bool isBoy) => isBoy ? boy : girl;
  static Color forGenderDeep(bool isBoy) => isBoy ? boyDeep : girlDeep;
  static Color forGenderSoft(bool isBoy) => isBoy ? boySoft : girlSoft;
  static LinearGradient genderGradient(bool isBoy) =>
      isBoy ? boyGradient : girlGradient;
}
