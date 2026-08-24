/// Kategori milestone perkembangan.
enum MilestoneCategory {
  grossMotor,
  fineMotor,
  language,
  social;

  String get label => switch (this) {
    MilestoneCategory.grossMotor => 'Motorik Kasar',
    MilestoneCategory.fineMotor => 'Motorik Halus',
    MilestoneCategory.language => 'Bicara & Bahasa',
    MilestoneCategory.social => 'Sosial & Kognitif',
  };
}

/// Definisi satu milestone perkembangan.
class MilestoneDef {
  const MilestoneDef({
    required this.id,
    required this.category,
    required this.title,
    required this.typicalMonths,
    required this.windowEndMonths,
  });

  final String id;
  final MilestoneCategory category;
  final String title;

  /// Usia khas pencapaian (bulan).
  final int typicalMonths;

  /// Batas akhir jendela wajar (bulan). Lewat ini → disarankan konsultasi.
  final int windowEndMonths;
}

/// Daftar milestone berbasis checklist perkembangan CDC/WHO,
/// disusun dalam Bahasa Indonesia untuk orang tua.
const List<MilestoneDef> kMilestones = [
  // ── 2 bulan ─────────────────────────────────────────────────────────────
  MilestoneDef(
    id: 'gm_2_head',
    category: MilestoneCategory.grossMotor,
    title: 'Mengangkat kepala saat tengkurap',
    typicalMonths: 2,
    windowEndMonths: 4,
  ),
  MilestoneDef(
    id: 'fm_2_hands',
    category: MilestoneCategory.fineMotor,
    title: 'Memandangi tangannya sendiri',
    typicalMonths: 2,
    windowEndMonths: 4,
  ),
  MilestoneDef(
    id: 'lg_2_coo',
    category: MilestoneCategory.language,
    title: 'Mengeluarkan suara "ooo/aaa" (cooing)',
    typicalMonths: 2,
    windowEndMonths: 4,
  ),
  MilestoneDef(
    id: 'sc_2_smile',
    category: MilestoneCategory.social,
    title: 'Tersenyum saat diajak bicara',
    typicalMonths: 2,
    windowEndMonths: 4,
  ),

  // ── 4 bulan ─────────────────────────────────────────────────────────────
  MilestoneDef(
    id: 'gm_4_headsteady',
    category: MilestoneCategory.grossMotor,
    title: 'Kepala tegak stabil saat digendong',
    typicalMonths: 4,
    windowEndMonths: 6,
  ),
  MilestoneDef(
    id: 'gm_4_roll',
    category: MilestoneCategory.grossMotor,
    title: 'Mulai berguling dari tengkurap ke telentang',
    typicalMonths: 4,
    windowEndMonths: 7,
  ),
  MilestoneDef(
    id: 'fm_4_grasp',
    category: MilestoneCategory.fineMotor,
    title: 'Menggenggam mainan yang diletakkan di tangan',
    typicalMonths: 4,
    windowEndMonths: 6,
  ),
  MilestoneDef(
    id: 'lg_4_laugh',
    category: MilestoneCategory.language,
    title: 'Tertawa keras',
    typicalMonths: 4,
    windowEndMonths: 6,
  ),
  MilestoneDef(
    id: 'sc_4_play',
    category: MilestoneCategory.social,
    title: 'Suka bermain dan bereaksi pada orang',
    typicalMonths: 4,
    windowEndMonths: 6,
  ),

  // ── 6 bulan ─────────────────────────────────────────────────────────────
  MilestoneDef(
    id: 'gm_6_sit',
    category: MilestoneCategory.grossMotor,
    title: 'Duduk dengan topangan',
    typicalMonths: 6,
    windowEndMonths: 8,
  ),
  MilestoneDef(
    id: 'gm_6_rollboth',
    category: MilestoneCategory.grossMotor,
    title: 'Berguling ke dua arah',
    typicalMonths: 6,
    windowEndMonths: 8,
  ),
  MilestoneDef(
    id: 'fm_6_transfer',
    category: MilestoneCategory.fineMotor,
    title: 'Memindahkan benda dari tangan ke tangan',
    typicalMonths: 6,
    windowEndMonths: 8,
  ),
  MilestoneDef(
    id: 'lg_6_babble',
    category: MilestoneCategory.language,
    title: 'Mengoceh berantai ("bababa")',
    typicalMonths: 6,
    windowEndMonths: 9,
  ),
  MilestoneDef(
    id: 'sc_6_stranger',
    category: MilestoneCategory.social,
    title: 'Mengenali wajah asing vs orang dekat',
    typicalMonths: 6,
    windowEndMonths: 9,
  ),

  // ── 9 bulan ─────────────────────────────────────────────────────────────
  MilestoneDef(
    id: 'gm_9_sitalone',
    category: MilestoneCategory.grossMotor,
    title: 'Duduk sendiri tanpa topangan',
    typicalMonths: 9,
    windowEndMonths: 11,
  ),
  MilestoneDef(
    id: 'gm_9_crawl',
    category: MilestoneCategory.grossMotor,
    title: 'Merangkak',
    typicalMonths: 9,
    windowEndMonths: 12,
  ),
  MilestoneDef(
    id: 'fm_9_pincer',
    category: MilestoneCategory.fineMotor,
    title: 'Menjimpit benda kecil (jempol-telunjuk)',
    typicalMonths: 9,
    windowEndMonths: 12,
  ),
  MilestoneDef(
    id: 'lg_9_mama',
    category: MilestoneCategory.language,
    title: 'Mengucap "mama/papa" (belum tepat sasaran)',
    typicalMonths: 9,
    windowEndMonths: 12,
  ),
  MilestoneDef(
    id: 'sc_9_peekaboo',
    category: MilestoneCategory.social,
    title: 'Suka bermain cilukba',
    typicalMonths: 9,
    windowEndMonths: 12,
  ),

  // ── 12 bulan ────────────────────────────────────────────────────────────
  MilestoneDef(
    id: 'gm_12_stand',
    category: MilestoneCategory.grossMotor,
    title: 'Berdiri berpegangan',
    typicalMonths: 12,
    windowEndMonths: 15,
  ),
  MilestoneDef(
    id: 'gm_12_cruise',
    category: MilestoneCategory.grossMotor,
    title: 'Berjalan berpegangan pada perabot',
    typicalMonths: 12,
    windowEndMonths: 15,
  ),
  MilestoneDef(
    id: 'fm_12_drop',
    category: MilestoneCategory.fineMotor,
    title: 'Meletakkan benda ke wadah',
    typicalMonths: 12,
    windowEndMonths: 15,
  ),
  MilestoneDef(
    id: 'lg_12_firstword',
    category: MilestoneCategory.language,
    title: 'Mengucap 1-2 kata bermakna ("mama" untuk ibu)',
    typicalMonths: 12,
    windowEndMonths: 16,
  ),
  MilestoneDef(
    id: 'sc_12_wave',
    category: MilestoneCategory.social,
    title: 'Melambaikan tangan "dadah"',
    typicalMonths: 12,
    windowEndMonths: 15,
  ),

  // ── 15 bulan ────────────────────────────────────────────────────────────
  MilestoneDef(
    id: 'gm_15_walk',
    category: MilestoneCategory.grossMotor,
    title: 'Berjalan sendiri beberapa langkah',
    typicalMonths: 15,
    windowEndMonths: 18,
  ),
  MilestoneDef(
    id: 'fm_15_scribble',
    category: MilestoneCategory.fineMotor,
    title: 'Mencoret-coret',
    typicalMonths: 15,
    windowEndMonths: 18,
  ),
  MilestoneDef(
    id: 'lg_15_3words',
    category: MilestoneCategory.language,
    title: 'Menguasai ±3 kata bermakna',
    typicalMonths: 15,
    windowEndMonths: 19,
  ),
  MilestoneDef(
    id: 'sc_15_hug',
    category: MilestoneCategory.social,
    title: 'Memeluk boneka/mainan kesayangan',
    typicalMonths: 15,
    windowEndMonths: 19,
  ),

  // ── 18 bulan ────────────────────────────────────────────────────────────
  MilestoneDef(
    id: 'gm_18_walksteady',
    category: MilestoneCategory.grossMotor,
    title: 'Berjalan mantap, bisa menarik mainan',
    typicalMonths: 18,
    windowEndMonths: 21,
  ),
  MilestoneDef(
    id: 'fm_18_spoon',
    category: MilestoneCategory.fineMotor,
    title: 'Makan sendiri dengan sendok (berantakan tak apa)',
    typicalMonths: 18,
    windowEndMonths: 22,
  ),
  MilestoneDef(
    id: 'fm_18_tower2',
    category: MilestoneCategory.fineMotor,
    title: 'Menyusun menara 2-3 kubus',
    typicalMonths: 18,
    windowEndMonths: 22,
  ),
  MilestoneDef(
    id: 'lg_18_10words',
    category: MilestoneCategory.language,
    title: 'Menguasai ±10 kata',
    typicalMonths: 18,
    windowEndMonths: 22,
  ),
  MilestoneDef(
    id: 'sc_18_point',
    category: MilestoneCategory.social,
    title: 'Menunjuk benda yang diinginkan/menarik',
    typicalMonths: 18,
    windowEndMonths: 20,
  ),

  // ── 24 bulan ────────────────────────────────────────────────────────────
  MilestoneDef(
    id: 'gm_24_run',
    category: MilestoneCategory.grossMotor,
    title: 'Berlari',
    typicalMonths: 24,
    windowEndMonths: 27,
  ),
  MilestoneDef(
    id: 'gm_24_stairs',
    category: MilestoneCategory.grossMotor,
    title: 'Naik tangga dengan pegangan',
    typicalMonths: 24,
    windowEndMonths: 28,
  ),
  MilestoneDef(
    id: 'gm_24_kick',
    category: MilestoneCategory.grossMotor,
    title: 'Menendang bola',
    typicalMonths: 24,
    windowEndMonths: 27,
  ),
  MilestoneDef(
    id: 'fm_24_tower4',
    category: MilestoneCategory.fineMotor,
    title: 'Menyusun menara 4-6 kubus',
    typicalMonths: 24,
    windowEndMonths: 28,
  ),
  MilestoneDef(
    id: 'lg_24_2words',
    category: MilestoneCategory.language,
    title: 'Merangkai 2 kata ("minta susu")',
    typicalMonths: 24,
    windowEndMonths: 28,
  ),
  MilestoneDef(
    id: 'sc_24_parallel',
    category: MilestoneCategory.social,
    title: 'Bermain di samping anak lain (parallel play)',
    typicalMonths: 24,
    windowEndMonths: 28,
  ),

  // ── 30 bulan ────────────────────────────────────────────────────────────
  MilestoneDef(
    id: 'gm_30_jump',
    category: MilestoneCategory.grossMotor,
    title: 'Melompat dua kaki bersamaan',
    typicalMonths: 30,
    windowEndMonths: 34,
  ),
  MilestoneDef(
    id: 'fm_30_turnpage',
    category: MilestoneCategory.fineMotor,
    title: 'Membalik halaman buku satu per satu',
    typicalMonths: 30,
    windowEndMonths: 34,
  ),
  MilestoneDef(
    id: 'lg_30_pronoun',
    category: MilestoneCategory.language,
    title: 'Memakai kata ganti ("aku", "kamu")',
    typicalMonths: 30,
    windowEndMonths: 34,
  ),
  MilestoneDef(
    id: 'sc_30_pretend',
    category: MilestoneCategory.social,
    title: 'Bermain pura-pura (masak-masakan)',
    typicalMonths: 30,
    windowEndMonths: 34,
  ),

  // ── 36 bulan ────────────────────────────────────────────────────────────
  MilestoneDef(
    id: 'gm_36_pedal',
    category: MilestoneCategory.grossMotor,
    title: 'Mengayuh sepeda roda tiga',
    typicalMonths: 36,
    windowEndMonths: 40,
  ),
  MilestoneDef(
    id: 'gm_36_stairsalt',
    category: MilestoneCategory.grossMotor,
    title: 'Naik tangga bergantian kaki',
    typicalMonths: 36,
    windowEndMonths: 42,
  ),
  MilestoneDef(
    id: 'fm_36_circle',
    category: MilestoneCategory.fineMotor,
    title: 'Meniru menggambar lingkaran',
    typicalMonths: 36,
    windowEndMonths: 42,
  ),
  MilestoneDef(
    id: 'lg_36_sentence',
    category: MilestoneCategory.language,
    title: 'Bicara kalimat 3 kata, dipahami orang lain',
    typicalMonths: 36,
    windowEndMonths: 42,
  ),
  MilestoneDef(
    id: 'sc_36_turn',
    category: MilestoneCategory.social,
    title: 'Mau bergiliran saat bermain',
    typicalMonths: 36,
    windowEndMonths: 42,
  ),

  // ── 48 bulan ────────────────────────────────────────────────────────────
  MilestoneDef(
    id: 'gm_48_hop',
    category: MilestoneCategory.grossMotor,
    title: 'Melompat satu kaki',
    typicalMonths: 48,
    windowEndMonths: 54,
  ),
  MilestoneDef(
    id: 'gm_48_catch',
    category: MilestoneCategory.grossMotor,
    title: 'Menangkap bola besar',
    typicalMonths: 48,
    windowEndMonths: 54,
  ),
  MilestoneDef(
    id: 'fm_48_person',
    category: MilestoneCategory.fineMotor,
    title: 'Menggambar orang 2-4 bagian tubuh',
    typicalMonths: 48,
    windowEndMonths: 54,
  ),
  MilestoneDef(
    id: 'lg_48_story',
    category: MilestoneCategory.language,
    title: 'Menceritakan kejadian sederhana',
    typicalMonths: 48,
    windowEndMonths: 54,
  ),
  MilestoneDef(
    id: 'sc_48_coop',
    category: MilestoneCategory.social,
    title: 'Bermain kerja sama dengan anak lain',
    typicalMonths: 48,
    windowEndMonths: 54,
  ),

  // ── 60 bulan ────────────────────────────────────────────────────────────
  MilestoneDef(
    id: 'gm_60_skip',
    category: MilestoneCategory.grossMotor,
    title: 'Melompat-lompat (skipping) dan berdiri satu kaki 10 detik',
    typicalMonths: 60,
    windowEndMonths: 66,
  ),
  MilestoneDef(
    id: 'fm_60_write',
    category: MilestoneCategory.fineMotor,
    title: 'Menulis beberapa huruf dan menyalin segitiga',
    typicalMonths: 60,
    windowEndMonths: 66,
  ),
  MilestoneDef(
    id: 'lg_60_converse',
    category: MilestoneCategory.language,
    title: 'Bercerita runtut dan menjawab pertanyaan sederhana',
    typicalMonths: 60,
    windowEndMonths: 66,
  ),
  MilestoneDef(
    id: 'sc_60_independent',
    category: MilestoneCategory.social,
    title: 'Mandi/berpakaian sebagian besar mandiri',
    typicalMonths: 60,
    windowEndMonths: 66,
  ),
];
