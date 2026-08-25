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
  static const Color paper = Color(0xFFFFFCF5);
  static const Color espresso = Color(0xFF35291F);

  // ── Tinta (teks) ───────────────────────────────────────────────────────
  static const Color ink = Color(0xFF2D2820);
  static const Color inkSoft = Color(0xFF7C7162);
  static const Color inkFaint = Color(0xFFB0A591);

  // ── Garis halus ────────────────────────────────────────────────────────
  static const Color hairline = Color(0xFFEBE2D1);

  // ── Palet malam Arunika ───────────────────────────────────────────────
  // Tetap hangat dan bertekstur; bukan hitam murni, agar aksen sunrise
  // terasa seperti cahaya kecil di atas ruang malam.
  static const Color nightCanvas = Color(0xFF17130F);
  static const Color nightSurface = Color(0xFF241E18);
  static const Color nightSurfaceRaised = Color(0xFF2D251E);
  static const Color nightText = Color(0xFFFFF2DF);
  static const Color nightTextSoft = Color(0xFFD2C2AD);
  static const Color nightTextFaint = Color(0xFFA89882);
  static const Color nightHairline = Color(0xFF4A3E32);
  static const Color nightGoldMist = Color(0xFF49391D);
  static const Color nightSageMist = Color(0xFF26382B);
  static const Color nightTerracottaMist = Color(0xFF432B24);
  static const Color nightLavenderMist = Color(0xFF342B3C);

  // ── Emas champagne (brand) ─────────────────────────────────────────────
  static const Color gold = Color(0xFFC29A3C);
  // Digelapkan demi kontras WCAG AA untuk teks kecil di atas ivory.
  static const Color goldDeep = Color(0xFF7E6220);
  static const Color goldSoft = Color(0xFFEBDCAF);
  static const Color goldMist = Color(0xFFF8F1DE);

  // ── Editorial Sunrise accents ─────────────────────────────────────────
  static const Color sage = Color(0xFF78927D);
  static const Color sageDeep = Color(0xFF4D6C58);
  static const Color sageMist = Color(0xFFE9F0E8);
  static const Color terracotta = Color(0xFFC6765E);
  static const Color terracottaDeep = Color(0xFF995442);
  static const Color terracottaMist = Color(0xFFF8E8DF);
  static const Color lavenderMist = Color(0xFFEDE8F0);

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

  static const LinearGradient sunrise = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFE9B9), Color(0xFFF3C980), Color(0xFFE09D72)],
  );

  static const LinearGradient sageGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFC8D9C4), Color(0xFF78927D)],
  );

  static const LinearGradient terracottaMistGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFE7DC), Color(0xFFF2C8B8)],
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
