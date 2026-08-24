/// Definisi satu jadwal vaksin.
class VaccineDef {
  const VaccineDef({
    required this.id,
    required this.name,
    required this.protects,
    required this.ageMonths,
    required this.ageLabel,
    this.optional = false,
  });

  final String id;
  final String name;

  /// Penyakit yang dilindungi.
  final String protects;

  /// Usia target pemberian (bulan).
  final int ageMonths;
  final String ageLabel;

  /// true = rekomendasi tambahan IDAI (di luar program nasional gratis).
  final bool optional;
}

/// Jadwal imunisasi anak Indonesia:
/// Program imunisasi rutin lengkap (Kemenkes) + rekomendasi tambahan IDAI.
/// Selalu konfirmasikan ke fasilitas kesehatan — jadwal dapat berubah.
const List<VaccineDef> kVaccines = [
  // ── Program nasional (imunisasi dasar lengkap) ───────────────────────────
  VaccineDef(
    id: 'hb0',
    name: 'Hepatitis B (HB-0)',
    protects: 'Hepatitis B',
    ageMonths: 0,
    ageLabel: 'Lahir (< 24 jam)',
  ),
  VaccineDef(
    id: 'bcg',
    name: 'BCG',
    protects: 'Tuberkulosis (TBC) berat',
    ageMonths: 1,
    ageLabel: '1 bulan',
  ),
  VaccineDef(
    id: 'polio1',
    name: 'Polio 1 (OPV)',
    protects: 'Poliomielitis',
    ageMonths: 1,
    ageLabel: '1 bulan',
  ),
  VaccineDef(
    id: 'dpt1',
    name: 'DPT-HB-Hib 1',
    protects: 'Difteri, Pertusis, Tetanus, Hepatitis B, Hib',
    ageMonths: 2,
    ageLabel: '2 bulan',
  ),
  VaccineDef(
    id: 'polio2',
    name: 'Polio 2 (OPV)',
    protects: 'Poliomielitis',
    ageMonths: 2,
    ageLabel: '2 bulan',
  ),
  VaccineDef(
    id: 'dpt2',
    name: 'DPT-HB-Hib 2',
    protects: 'Difteri, Pertusis, Tetanus, Hepatitis B, Hib',
    ageMonths: 3,
    ageLabel: '3 bulan',
  ),
  VaccineDef(
    id: 'polio3',
    name: 'Polio 3 (OPV)',
    protects: 'Poliomielitis',
    ageMonths: 3,
    ageLabel: '3 bulan',
  ),
  VaccineDef(
    id: 'dpt3',
    name: 'DPT-HB-Hib 3',
    protects: 'Difteri, Pertusis, Tetanus, Hepatitis B, Hib',
    ageMonths: 4,
    ageLabel: '4 bulan',
  ),
  VaccineDef(
    id: 'polio4',
    name: 'Polio 4 (OPV)',
    protects: 'Poliomielitis',
    ageMonths: 4,
    ageLabel: '4 bulan',
  ),
  VaccineDef(
    id: 'ipv',
    name: 'IPV',
    protects: 'Poliomielitis (suntik)',
    ageMonths: 4,
    ageLabel: '4 bulan',
  ),
  VaccineDef(
    id: 'mr1',
    name: 'Campak / MR',
    protects: 'Campak dan Rubella',
    ageMonths: 9,
    ageLabel: '9 bulan',
  ),
  VaccineDef(
    id: 'dpt4',
    name: 'DPT-HB-Hib Lanjutan',
    protects: 'Difteri, Pertusis, Tetanus, Hepatitis B, Hib',
    ageMonths: 18,
    ageLabel: '18 bulan',
  ),
  VaccineDef(
    id: 'mr2',
    name: 'Campak / MR Lanjutan',
    protects: 'Campak dan Rubella',
    ageMonths: 18,
    ageLabel: '18 bulan',
  ),

  // ── Rekomendasi tambahan IDAI ────────────────────────────────────────────
  VaccineDef(
    id: 'pcv1',
    name: 'PCV 1',
    protects: 'Pneumonia & meningitis (pneumokokus)',
    ageMonths: 2,
    ageLabel: '2 bulan',
    optional: true,
  ),
  VaccineDef(
    id: 'pcv2',
    name: 'PCV 2',
    protects: 'Pneumonia & meningitis (pneumokokus)',
    ageMonths: 4,
    ageLabel: '4 bulan',
    optional: true,
  ),
  VaccineDef(
    id: 'pcv3',
    name: 'PCV 3 (booster)',
    protects: 'Pneumonia & meningitis (pneumokokus)',
    ageMonths: 12,
    ageLabel: '12 bulan',
    optional: true,
  ),
  VaccineDef(
    id: 'rota1',
    name: 'Rotavirus 1',
    protects: 'Diare berat akibat rotavirus',
    ageMonths: 2,
    ageLabel: '2 bulan',
    optional: true,
  ),
  VaccineDef(
    id: 'rota2',
    name: 'Rotavirus 2',
    protects: 'Diare berat akibat rotavirus',
    ageMonths: 4,
    ageLabel: '4 bulan',
    optional: true,
  ),
  VaccineDef(
    id: 'flu1',
    name: 'Influenza (tahunan)',
    protects: 'Influenza',
    ageMonths: 6,
    ageLabel: 'Mulai 6 bulan, tiap tahun',
    optional: true,
  ),
  VaccineDef(
    id: 'varisela',
    name: 'Varisela',
    protects: 'Cacar air',
    ageMonths: 12,
    ageLabel: '12 bulan',
    optional: true,
  ),
  VaccineDef(
    id: 'mmr',
    name: 'MMR',
    protects: 'Campak, Gondongan, Rubella',
    ageMonths: 15,
    ageLabel: '15 bulan',
    optional: true,
  ),
  VaccineDef(
    id: 'tifoid',
    name: 'Tifoid',
    protects: 'Demam tifoid',
    ageMonths: 24,
    ageLabel: '24 bulan',
    optional: true,
  ),
  VaccineDef(
    id: 'hepa',
    name: 'Hepatitis A',
    protects: 'Hepatitis A',
    ageMonths: 24,
    ageLabel: '24 bulan (2 dosis)',
    optional: true,
  ),
  VaccineDef(
    id: 'hpv',
    name: 'HPV',
    protects: 'Kanker serviks (khusus anak perempuan)',
    ageMonths: 120,
    ageLabel: '10-13 tahun',
    optional: true,
  ),
];
