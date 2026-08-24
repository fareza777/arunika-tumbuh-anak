/// Panduan gizi harian anak berbasis acuan resmi:
/// - Angka Kecukupan Gizi (AKG): Permenkes RI No. 28 Tahun 2019.
/// - Frekuensi & porsi MP-ASI: WHO / Kemenkes RI.
///
/// Angka di sini adalah ACUAN UMUM untuk anak sehat per kelompok usia,
/// bukan resep individu. Selalu konsultasikan ke tenaga kesehatan.
library;

/// Satu baris item checklist harian.
class ChecklistItem {
  const ChecklistItem({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final String icon; // nama ikon dipetakan di UI
}

/// Panduan gizi untuk satu kelompok usia.
class NutritionGuide {
  const NutritionGuide({
    required this.minMonths,
    required this.maxMonths,
    required this.ageLabel,
    required this.energyKkal,
    required this.proteinG,
    required this.fatG,
    required this.carbsG,
    required this.waterMl,
    required this.frequency,
    required this.portion,
    required this.texture,
    required this.checklist,
  });

  final int minMonths; // inklusif
  final int maxMonths; // eksklusif
  final String ageLabel;

  // AKG 2019 per orang per hari.
  final int energyKkal;
  final int proteinG;
  final int fatG;
  final int carbsG;
  final int waterMl;

  // Panduan pemberian makan (WHO/Kemenkes).
  final String frequency;
  final String portion;
  final String texture;

  final List<ChecklistItem> checklist;
}

/// Pesan kunci gizi seimbang anak (berlaku umum, Kemenkes/IDAI).
const List<String> kNutritionKeyMessages = [
  'Berikan protein hewani setiap hari (telur, ikan, ayam, hati ayam, susu) — terbukti membantu mencegah stunting.',
  'Jangan membatasi lemak untuk anak di bawah 2 tahun; lemak penting untuk otak.',
  'Batasi gula, garam, dan minyak. Hindari minuman berpemanis dan makanan ringan kemasan.',
  'Naikkan tekstur makanan bertahap sesuai usia agar kemampuan mengunyah berkembang.',
  'Jadikan air putih minuman utama setelah usia 6 bulan.',
  'Makanlah bersama anak dengan suasana menyenangkan; jangan memaksa atau mengalihkan dengan layar.',
];

const List<NutritionGuide> kNutritionGuides = [
  NutritionGuide(
    minMonths: 0,
    maxMonths: 6,
    ageLabel: '0-5 bulan',
    energyKkal: 550,
    proteinG: 9,
    fatG: 31,
    carbsG: 58,
    waterMl: 700,
    frequency: 'ASI eksklusif on demand, sekitar 8-12 kali per hari.',
    portion:
        'Sesuai keinginan bayi; tidak perlu makanan/minuman lain termasuk air putih.',
    texture: 'ASI saja (tanpa MP-ASI).',
    checklist: [
      ChecklistItem(
        id: 'asi',
        label: 'ASI on demand hari ini (8-12x)',
        icon: 'mother',
      ),
      ChecklistItem(
        id: 'vitd',
        label: 'Siangkan sebentar / vitamin D sesuai anjuran',
        icon: 'sun',
      ),
    ],
  ),
  NutritionGuide(
    minMonths: 6,
    maxMonths: 9,
    ageLabel: '6-8 bulan',
    energyKkal: 800,
    proteinG: 15,
    fatG: 36,
    carbsG: 105,
    waterMl: 900,
    frequency: 'MP-ASI 2-3 kali makan utama per hari, ASI tetap dilanjutkan.',
    portion:
        'Mulai 2-3 sendok makan per kali makan, naik bertahap hingga ½ mangkuk (250 ml).',
    texture: 'Lumat halus (puree) → lumat kasar.',
    checklist: [
      ChecklistItem(
        id: 'main_meals',
        label: 'Makan utama 2-3x hari ini',
        icon: 'meal',
      ),
      ChecklistItem(
        id: 'animal_protein',
        label: 'Protein hewani (telur/ikan/ayam/hati)',
        icon: 'protein',
      ),
      ChecklistItem(id: 'veggie_fruit', label: 'Sayur & buah', icon: 'veggie'),
      ChecklistItem(id: 'milk', label: 'ASI tetap diberikan', icon: 'mother'),
    ],
  ),
  NutritionGuide(
    minMonths: 9,
    maxMonths: 12,
    ageLabel: '9-11 bulan',
    energyKkal: 800,
    proteinG: 15,
    fatG: 36,
    carbsG: 105,
    waterMl: 900,
    frequency:
        'MP-ASI 3-4 kali makan utama + 1-2 kali camilan per hari, ASI dilanjutkan.',
    portion: 'Sekitar ½ mangkuk (250 ml) per kali makan.',
    texture: 'Cincang halus → cincang kasar (finger food boleh dikenalkan).',
    checklist: [
      ChecklistItem(
        id: 'main_meals',
        label: 'Makan utama 3-4x hari ini',
        icon: 'meal',
      ),
      ChecklistItem(id: 'snack', label: 'Camilan sehat 1-2x', icon: 'snack'),
      ChecklistItem(
        id: 'animal_protein',
        label: 'Protein hewani (telur/ikan/ayam/hati)',
        icon: 'protein',
      ),
      ChecklistItem(id: 'veggie_fruit', label: 'Sayur & buah', icon: 'veggie'),
      ChecklistItem(id: 'milk', label: 'ASI tetap diberikan', icon: 'mother'),
    ],
  ),
  NutritionGuide(
    minMonths: 12,
    maxMonths: 24,
    ageLabel: '12-23 bulan',
    energyKkal: 1125,
    proteinG: 26,
    fatG: 50,
    carbsG: 155,
    waterMl: 1200,
    frequency:
        'Makanan keluarga 3-4 kali makan utama + 1-2 kali camilan per hari.',
    portion: '¾ sampai 1 mangkuk (250 ml) per kali makan.',
    texture: 'Makanan keluarga, dicincang bila perlu.',
    checklist: [
      ChecklistItem(
        id: 'main_meals',
        label: 'Makan utama 3-4x hari ini',
        icon: 'meal',
      ),
      ChecklistItem(id: 'snack', label: 'Camilan sehat 1-2x', icon: 'snack'),
      ChecklistItem(
        id: 'animal_protein',
        label: 'Protein hewani (telur/ikan/ayam/susu)',
        icon: 'protein',
      ),
      ChecklistItem(id: 'veggie_fruit', label: 'Sayur & buah', icon: 'veggie'),
      ChecklistItem(id: 'water', label: 'Air putih cukup', icon: 'water'),
    ],
  ),
  NutritionGuide(
    minMonths: 24,
    maxMonths: 48,
    ageLabel: '2-3 tahun',
    energyKkal: 1125,
    proteinG: 26,
    fatG: 50,
    carbsG: 155,
    waterMl: 1200,
    frequency: '3 kali makan utama + 2 kali camilan sehat, jam makan teratur.',
    portion:
        '1 piring anak per kali makan, ikuti "Isi Piringku": ½ sayur & buah, ¼ lauk, ¼ makanan pokok.',
    texture: 'Makanan keluarga.',
    checklist: [
      ChecklistItem(
        id: 'main_meals',
        label: 'Makan utama 3x hari ini',
        icon: 'meal',
      ),
      ChecklistItem(id: 'snack', label: 'Camilan sehat 2x', icon: 'snack'),
      ChecklistItem(
        id: 'animal_protein',
        label: 'Protein hewani (telur/ikan/ayam/susu)',
        icon: 'protein',
      ),
      ChecklistItem(
        id: 'veggie_fruit',
        label: 'Sayur & buah (½ piring)',
        icon: 'veggie',
      ),
      ChecklistItem(id: 'water', label: 'Air putih cukup', icon: 'water'),
    ],
  ),
  NutritionGuide(
    minMonths: 48,
    maxMonths: 84,
    ageLabel: '4-6 tahun',
    energyKkal: 1600,
    proteinG: 35,
    fatG: 65,
    carbsG: 215,
    waterMl: 1500,
    frequency: '3 kali makan utama + 2 kali camilan sehat, jam makan teratur.',
    portion: 'Ikuti "Isi Piringku": ½ sayur & buah, ¼ lauk, ¼ makanan pokok.',
    texture: 'Makanan keluarga.',
    checklist: [
      ChecklistItem(
        id: 'main_meals',
        label: 'Makan utama 3x hari ini',
        icon: 'meal',
      ),
      ChecklistItem(id: 'snack', label: 'Camilan sehat 2x', icon: 'snack'),
      ChecklistItem(
        id: 'animal_protein',
        label: 'Protein hewani (telur/ikan/ayam/susu)',
        icon: 'protein',
      ),
      ChecklistItem(
        id: 'veggie_fruit',
        label: 'Sayur & buah (½ piring)',
        icon: 'veggie',
      ),
      ChecklistItem(id: 'water', label: 'Air putih cukup', icon: 'water'),
    ],
  ),
  NutritionGuide(
    minMonths: 84,
    maxMonths: 120,
    ageLabel: '7-9 tahun',
    energyKkal: 1850,
    proteinG: 40,
    fatG: 70,
    carbsG: 250,
    waterMl: 1700,
    frequency: '3 kali makan utama + 2 kali camilan sehat, jam makan teratur.',
    portion: 'Ikuti "Isi Piringku": ½ sayur & buah, ¼ lauk, ¼ makanan pokok.',
    texture: 'Makanan keluarga.',
    checklist: [
      ChecklistItem(
        id: 'main_meals',
        label: 'Makan utama 3x hari ini',
        icon: 'meal',
      ),
      ChecklistItem(id: 'snack', label: 'Camilan sehat 2x', icon: 'snack'),
      ChecklistItem(
        id: 'animal_protein',
        label: 'Protein hewani (telur/ikan/ayam/susu)',
        icon: 'protein',
      ),
      ChecklistItem(
        id: 'veggie_fruit',
        label: 'Sayur & buah (½ piring)',
        icon: 'veggie',
      ),
      ChecklistItem(id: 'water', label: 'Air putih cukup', icon: 'water'),
    ],
  ),
];

/// Panduan untuk usia (bulan) tertentu. Di atas 9 tahun memakai kelompok terakhir.
NutritionGuide nutritionGuideFor(double ageMonths) {
  for (final guide in kNutritionGuides) {
    if (ageMonths >= guide.minMonths && ageMonths < guide.maxMonths) {
      return guide;
    }
  }
  return kNutritionGuides.last;
}
