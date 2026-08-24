import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Tingkat status untuk pewarnaan UI.
enum StatusLevel { good, info, warn, danger }

/// Hasil klasifikasi satu indikator, lengkap dengan saran untuk orang tua.
class Classification {
  const Classification({
    required this.label,
    required this.level,
    required this.description,
    required this.advice,
  });

  final String label;
  final StatusLevel level;
  final String description;
  final String advice;

  Color get color => switch (level) {
    StatusLevel.good => AppColors.good,
    StatusLevel.info => AppColors.info,
    StatusLevel.warn => AppColors.warn,
    StatusLevel.danger => AppColors.danger,
  };

  IconData get icon => switch (level) {
    StatusLevel.good => Icons.check_circle_rounded,
    StatusLevel.info => Icons.info_rounded,
    StatusLevel.warn => Icons.warning_amber_rounded,
    StatusLevel.danger => Icons.error_rounded,
  };
}

/// Klasifikasi status gizi sesuai Permenkes RI No. 2 Tahun 2020
/// (standar antropometri anak, berbasis WHO) dan rujukan WHO 2007
/// untuk usia 5-19 tahun.
class NutritionClassifier {
  NutritionClassifier._();

  static const _konsultasi =
      'Perbanyak konsultasi ke Posyandu atau Puskesmas untuk pemantauan rutin.';

  // ── BB/U (0-5 tahun, Permenkes) ──────────────────────────────────────────
  static Classification weightForAge(double z) {
    if (z < -3) {
      return const Classification(
        label: 'Berat Badan Sangat Kurang',
        level: StatusLevel.danger,
        description:
            'Berat badan anak jauh di bawah rentang wajar usianya (z < -3).',
        advice:
            'Segera periksakan anak ke Puskesmas atau dokter anak untuk evaluasi menyeluruh dan tata laksana gizi. $_konsultasi',
      );
    }
    if (z < -2) {
      return const Classification(
        label: 'Berat Badan Kurang',
        level: StatusLevel.warn,
        description:
            'Berat badan anak di bawah rentang wajar usianya (-3 ≤ z < -2).',
        advice:
            'Tingkatkan asupan makanan bergizi seimbang dan pantau berat badan tiap bulan di Posyandu. Konsultasikan ke tenaga kesehatan bila berat tidak naik.',
      );
    }
    if (z <= 1) {
      return const Classification(
        label: 'Berat Badan Normal',
        level: StatusLevel.good,
        description:
            'Berat badan anak berada dalam rentang wajar usianya (-2 ≤ z ≤ +1).',
        advice:
            'Pertahankan pola makan bergizi seimbang, ASI/susu sesuai usia, dan jadwal pemantauan rutin. $_konsultasi',
      );
    }
    return const Classification(
      label: 'Risiko Berat Badan Lebih',
      level: StatusLevel.warn,
      description: 'Berat badan anak di atas rentang wajar usianya (z > +1).',
      advice:
          'Perhatikan keseimbangan asupan dan aktivitas fisik anak. Kurangi makanan manis dan berlemak berlebih, konsultasikan ke tenaga kesehatan.',
    );
  }

  // ── TB/U (0-5 tahun, Permenkes) ──────────────────────────────────────────
  static Classification heightForAge(double z) {
    if (z < -3) {
      return const Classification(
        label: 'Sangat Pendek',
        level: StatusLevel.danger,
        description:
            'Tinggi badan anak jauh di bawah rentang wajar usianya (z < -3).',
        advice:
            'Anak berisiko stunting berat. Segera konsultasikan ke Puskesmas/dokter untuk evaluasi gizi dan riwayat kesehatan. Intervensi dini sangat membantu.',
      );
    }
    if (z < -2) {
      return const Classification(
        label: 'Pendek',
        level: StatusLevel.warn,
        description:
            'Tinggi badan anak di bawah rentang wajar usianya (-3 ≤ z < -2).',
        advice:
            'Anak terindikasi stunting. Perbaiki asupan protein hewani (telur, ikan, susu), jaga kebersihan, dan rutin ke Posyandu untuk pemantauan.',
      );
    }
    if (z <= 3) {
      return const Classification(
        label: 'Tinggi Badan Normal',
        level: StatusLevel.good,
        description:
            'Tinggi badan anak berada dalam rentang wajar usianya (-2 ≤ z ≤ +3).',
        advice:
            'Pertahankan asupan gizi seimbang dan tidur cukup untuk mendukung pertumbuhan optimal. $_konsultasi',
      );
    }
    return const Classification(
      label: 'Tinggi',
      level: StatusLevel.info,
      description: 'Tinggi badan anak di atas rentang umum usianya (z > +3).',
      advice:
          'Umumnya variasi normal, terutama bila orang tua juga tinggi. Bila disertai keluhan lain, konsultasikan ke dokter anak.',
    );
  }

  // ── BB/TB (0-5 tahun, Permenkes) ─────────────────────────────────────────
  static Classification weightForHeight(double z) {
    if (z < -3) {
      return const Classification(
        label: 'Gizi Buruk',
        level: StatusLevel.danger,
        description:
            'Berat badan sangat kurang terhadap tinggi badan (z < -3).',
        advice:
            'Kondisi ini membutuhkan penanganan segera. Bawa anak ke Puskesmas/dokter hari ini juga untuk tata laksana gizi buruk.',
      );
    }
    if (z < -2) {
      return const Classification(
        label: 'Gizi Kurang',
        level: StatusLevel.warn,
        description: 'Berat badan kurang terhadap tinggi badan (-3 ≤ z < -2).',
        advice:
            'Tingkatkan frekuensi dan kualitas makan anak dengan makanan padat gizi. Pantau berat tiap 2 minggu dan konsultasikan ke tenaga kesehatan.',
      );
    }
    if (z <= 1) {
      return const Classification(
        label: 'Gizi Baik',
        level: StatusLevel.good,
        description:
            'Berat badan anak seimbang dengan tinggi badannya (-2 ≤ z ≤ +1).',
        advice:
            'Pertahankan pola makan bergizi seimbang dan kebiasaan makan teratur. $_konsultasi',
      );
    }
    if (z <= 2) {
      return const Classification(
        label: 'Berisiko Gizi Lebih',
        level: StatusLevel.warn,
        description:
            'Berat badan mulai berlebih terhadap tinggi badan (+1 < z ≤ +2).',
        advice:
            'Jaga keseimbangan asupan: batasi makanan manis, gorengan, dan minuman berpemanis. Ajak anak aktif bergerak setiap hari.',
      );
    }
    if (z <= 3) {
      return const Classification(
        label: 'Gizi Lebih',
        level: StatusLevel.danger,
        description:
            'Berat badan berlebih terhadap tinggi badan (+2 < z ≤ +3).',
        advice:
            'Konsultasikan ke tenaga kesehatan untuk panduan pengaturan makan dan aktivitas fisik yang aman untuk anak.',
      );
    }
    return const Classification(
      label: 'Obesitas',
      level: StatusLevel.danger,
      description: 'Berat badan jauh berlebih terhadap tinggi badan (z > +3).',
      advice:
          'Disarankan evaluasi oleh dokter anak/ahli gizi untuk program penanganan obesitas anak yang terpandu dan menyenangkan.',
    );
  }

  // ── IMT/U 0-5 tahun (Permenkes, sama dengan BB/TB) ───────────────────────
  static Classification bmiForAgeUnder5(double z) => weightForHeight(z);

  // ── IMT/U 5-19 tahun (WHO 2007) ──────────────────────────────────────────
  static Classification bmiForAge5to19(double z) {
    if (z < -3) {
      return const Classification(
        label: 'Sangat Kurus',
        level: StatusLevel.danger,
        description: 'IMT anak jauh di bawah rentang wajar usianya (z < -3).',
        advice:
            'Segera konsultasikan ke Puskesmas/dokter untuk evaluasi penyebab dan perbaikan gizi.',
      );
    }
    if (z < -2) {
      return const Classification(
        label: 'Kurus',
        level: StatusLevel.warn,
        description: 'IMT anak di bawah rentang wajar usianya (-3 ≤ z < -2).',
        advice:
            'Tingkatkan asupan makanan bergizi dan pantau berat badan berkala. Konsultasikan ke tenaga kesehatan bila tidak membaik.',
      );
    }
    if (z <= 1) {
      return const Classification(
        label: 'Gizi Baik',
        level: StatusLevel.good,
        description:
            'IMT anak berada dalam rentang wajar usianya (-2 ≤ z ≤ +1).',
        advice:
            'Pertahankan pola makan seimbang dan aktivitas fisik rutin. $_konsultasi',
      );
    }
    if (z <= 2) {
      return const Classification(
        label: 'Berat Badan Lebih',
        level: StatusLevel.warn,
        description: 'IMT anak di atas rentang wajar usianya (+1 < z ≤ +2).',
        advice:
            'Batasi makanan tinggi gula dan lemak, perbanyak sayur buah, dan ajak anak aktif bergerak minimal 60 menit sehari.',
      );
    }
    return const Classification(
      label: 'Obesitas',
      level: StatusLevel.danger,
      description: 'IMT anak jauh di atas rentang wajar usianya (z > +2).',
      advice:
          'Disarankan konsultasi ke dokter anak/ahli gizi untuk panduan penanganan yang tepat dan ramah anak.',
    );
  }

  // ── LK/U (0-5 tahun, Permenkes) ──────────────────────────────────────────
  static Classification headCircumference(double z) {
    if (z < -2) {
      return const Classification(
        label: 'Mikrosefali (Evaluasi)',
        level: StatusLevel.danger,
        description: 'Lingkar kepala di bawah rentang wajar usianya (z < -2).',
        advice:
            'Disarankan evaluasi ke dokter anak untuk memastikan perkembangan otak berjalan baik. Jangan panik — pengukuran ulang yang teliti juga penting.',
      );
    }
    if (z <= 2) {
      return const Classification(
        label: 'Lingkar Kepala Normal',
        level: StatusLevel.good,
        description:
            'Lingkar kepala anak berada dalam rentang wajar usianya (-2 ≤ z ≤ +2).',
        advice:
            'Pertahankan stimulasi dan nutrisi yang baik untuk perkembangan otak anak.',
      );
    }
    return const Classification(
      label: 'Makrosefali (Evaluasi)',
      level: StatusLevel.warn,
      description: 'Lingkar kepala di atas rentang wajar usianya (z > +2).',
      advice:
          'Disarankan evaluasi ke dokter anak, terutama bila pembesaran terjadi cepat. Sering kali merupakan variasi familial (orang tua berkepala besar).',
    );
  }

  // ── LILA / MUAC (6-59 bulan) ─────────────────────────────────────────────
  static Classification muac(double cm) {
    if (cm < 11.5) {
      return const Classification(
        label: 'Gizi Buruk (LILA)',
        level: StatusLevel.danger,
        description: 'Lingkar lengan atas < 11,5 cm pada usia 6-59 bulan.',
        advice:
            'Segera bawa anak ke Puskesmas untuk penanganan gizi buruk sesuai tata laksana.',
      );
    }
    if (cm < 12.5) {
      return const Classification(
        label: 'Gizi Kurang (LILA)',
        level: StatusLevel.warn,
        description: 'Lingkar lengan atas 11,5-12,5 cm pada usia 6-59 bulan.',
        advice:
            'Tingkatkan makanan padat gizi dan pantau ketat tiap 2 minggu di Posyandu.',
      );
    }
    return const Classification(
      label: 'Normal (LILA)',
      level: StatusLevel.good,
      description: 'Lingkar lengan atas ≥ 12,5 cm.',
      advice: 'Pertahankan asupan gizi seimbang anak.',
    );
  }
}
