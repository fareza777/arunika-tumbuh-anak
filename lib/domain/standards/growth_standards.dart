/// Standar rujukan pertumbuhan yang tersedia di aplikasi.
enum GrowthStandard {
  /// WHO otomatis: 0-5 tahun (2006) lalu 5-19 tahun (2007).
  whoAuto,
  who2006,
  who2007,
  cdc2000;

  String get label => switch (this) {
    GrowthStandard.whoAuto => 'WHO (Otomatis)',
    GrowthStandard.who2006 => 'WHO 0-5 Tahun',
    GrowthStandard.who2007 => 'WHO 5-19 Tahun',
    GrowthStandard.cdc2000 => 'CDC 2000',
  };

  String get shortLabel => switch (this) {
    GrowthStandard.whoAuto => 'WHO',
    GrowthStandard.who2006 => 'WHO 0-5',
    GrowthStandard.who2007 => 'WHO 5-19',
    GrowthStandard.cdc2000 => 'CDC',
  };

  String get description => switch (this) {
    GrowthStandard.whoAuto =>
      'Standar WHO: kurva 0-5 tahun untuk balita, lalu otomatis berpindah ke rujukan WHO 5-19 tahun. Sesuai Permenkes No. 2/2020.',
    GrowthStandard.who2006 =>
      'WHO Child Growth Standards 2006. Standar resmi untuk anak 0-60 bulan (Permenkes No. 2/2020).',
    GrowthStandard.who2007 =>
      'WHO Growth Reference 2007 untuk anak usia 5-19 tahun (61-228 bulan).',
    GrowthStandard.cdc2000 =>
      'Kurva rujukan CDC 2000 (Amerika Serikat) untuk usia 0-20 tahun.',
  };
}

/// Indikator antropometri.
enum GrowthIndicator {
  /// Berat badan menurut umur (BB/U).
  wfa,

  /// Panjang/tinggi badan menurut umur (PB/U atau TB/U).
  lhfa,

  /// Berat badan menurut panjang/tinggi badan (BB/PB atau BB/TB).
  wflh,

  /// Indeks massa tubuh menurut umur (IMT/U).
  bfa,

  /// Lingkar kepala menurut umur (LK/U).
  hcfa;

  String get label => switch (this) {
    GrowthIndicator.wfa => 'Berat menurut Umur',
    GrowthIndicator.lhfa => 'Tinggi menurut Umur',
    GrowthIndicator.wflh => 'Berat menurut Tinggi',
    GrowthIndicator.bfa => 'IMT menurut Umur',
    GrowthIndicator.hcfa => 'Lingkar Kepala menurut Umur',
  };

  String get shortLabel => switch (this) {
    GrowthIndicator.wfa => 'BB/U',
    GrowthIndicator.lhfa => 'TB/U',
    GrowthIndicator.wflh => 'BB/TB',
    GrowthIndicator.bfa => 'IMT/U',
    GrowthIndicator.hcfa => 'LK/U',
  };

  String get unit => switch (this) {
    GrowthIndicator.wfa => 'kg',
    GrowthIndicator.lhfa => 'cm',
    GrowthIndicator.wflh => 'kg',
    GrowthIndicator.bfa => 'kg/m²',
    GrowthIndicator.hcfa => 'cm',
  };

  /// Satuan sumbu-X: bulan untuk indikator menurut umur, cm untuk BB/TB.
  String get xUnit => this == GrowthIndicator.wflh ? 'cm' : 'bulan';

  String get xLabel => this == GrowthIndicator.wflh
      ? 'Panjang/Tinggi Badan (cm)'
      : 'Umur (bulan)';
}
