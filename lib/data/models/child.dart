/// Jenis kelamin anak.
enum Gender {
  boy,
  girl;

  String get label => this == Gender.boy ? 'Laki-laki' : 'Perempuan';
  String get shortLabel => this == Gender.boy ? 'L' : 'P';

  static Gender fromString(String value) =>
      value == 'girl' ? Gender.girl : Gender.boy;
}

/// Profil anak.
class Child {
  const Child({
    required this.id,
    required this.name,
    required this.gender,
    required this.birthDate,
    this.photoPath,
    this.birthWeight,
    this.birthHeight,
    this.birthHead,
    this.fatherHeight,
    this.motherHeight,
    this.gestationalWeeks,
    required this.createdAt,
  });

  final String id;
  final String name;
  final Gender gender;
  final DateTime birthDate;
  final String? photoPath;

  /// Antropometri lahir (opsional, untuk titik awal grafik).
  final double? birthWeight; // kg
  final double? birthHeight; // cm
  final double? birthHead; // cm

  /// Tinggi orang tua untuk prediksi tinggi dewasa (cm).
  final double? fatherHeight;
  final double? motherHeight;

  /// Usia kehamilan saat lahir (minggu). Null = cukup bulan / tidak tahu.
  final int? gestationalWeeks;

  final int createdAt;

  bool get isBoy => gender == Gender.boy;

  /// Lahir prematur bila usia kehamilan < 37 minggu.
  bool get isPreterm => gestationalWeeks != null && gestationalWeeks! < 37;

  /// Hari yang dipangkas untuk koreksi prematur.
  int get _correctionDays => isPreterm ? (40 - gestationalWeeks!) * 7 : 0;

  int get ageInDays => DateTime.now().difference(birthDate).inDays;

  /// Koreksi usia prematur hanya berlaku sampai usia kronologis 24 bulan
  /// (rekomendasi WHO/AAP). Lewat itu dipakai usia kronologis biasa.
  bool get usesCorrectedAge => isPreterm && ageInDays < 731;

  /// Umur dalam bulan (konvensi WHO: 1 tahun = 365,25 hari).
  double get ageInMonths => ageInDays / 30.4375;

  /// Umur dalam bulan penuh (dibulatkan ke bawah) — dipakai untuk tabel.
  int get completedMonths => (ageInDays / 30.4375).floor();

  int get ageInYears => (ageInDays / 365.25).floor();

  /// Label umur ramah: "12 hari", "5 bulan", "2 th 3 bln".
  String get ageLabel {
    final days = ageInDays;
    if (days < 60) return '$days hari';
    final totalMonths = (days / 30.4375).floor();
    if (totalMonths < 24) return '$totalMonths bulan';
    final years = totalMonths ~/ 12;
    final months = totalMonths % 12;
    if (months == 0) return '$years tahun';
    return '$years th $months bln';
  }

  /// Umur pada tanggal tertentu (dalam bulan desimal, kronologis).
  double ageMonthsAt(DateTime date) =>
      date.difference(birthDate).inDays / 30.4375;

  /// Umur efektif untuk PENILAIAN pertumbuhan: usia terkoreksi bila anak
  /// prematur dan masih di bawah 24 bulan, selain itu sama dengan kronologis.
  double effectiveAgeMonthsAt(DateTime date) {
    final days = date.difference(birthDate).inDays;
    if (!isPreterm || days >= 731) return days / 30.4375;
    return (days - _correctionDays) / 30.4375;
  }

  /// Umur efektif saat ini (bulan desimal).
  double get effectiveAgeInMonths => effectiveAgeMonthsAt(DateTime.now());

  Child copyWith({
    String? name,
    Gender? gender,
    DateTime? birthDate,
    String? photoPath,
    double? birthWeight,
    double? birthHeight,
    double? birthHead,
    double? fatherHeight,
    double? motherHeight,
    int? gestationalWeeks,
    bool clearPhoto = false,
    bool clearGestational = false,
  }) {
    return Child(
      id: id,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
      birthWeight: birthWeight ?? this.birthWeight,
      birthHeight: birthHeight ?? this.birthHeight,
      birthHead: birthHead ?? this.birthHead,
      fatherHeight: fatherHeight ?? this.fatherHeight,
      motherHeight: motherHeight ?? this.motherHeight,
      gestationalWeeks: clearGestational
          ? null
          : (gestationalWeeks ?? this.gestationalWeeks),
      createdAt: createdAt,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'gender': gender.name,
    'birth_date': birthDate.millisecondsSinceEpoch,
    'photo_path': photoPath,
    'birth_weight': birthWeight,
    'birth_height': birthHeight,
    'birth_head': birthHead,
    'father_height': fatherHeight,
    'mother_height': motherHeight,
    'gestational_weeks': gestationalWeeks,
    'created_at': createdAt,
  };

  static Child fromMap(Map<String, Object?> map) => Child(
    id: map['id'] as String,
    name: map['name'] as String,
    gender: Gender.fromString(map['gender'] as String),
    birthDate: DateTime.fromMillisecondsSinceEpoch(map['birth_date'] as int),
    photoPath: map['photo_path'] as String?,
    birthWeight: (map['birth_weight'] as num?)?.toDouble(),
    birthHeight: (map['birth_height'] as num?)?.toDouble(),
    birthHead: (map['birth_head'] as num?)?.toDouble(),
    fatherHeight: (map['father_height'] as num?)?.toDouble(),
    motherHeight: (map['mother_height'] as num?)?.toDouble(),
    gestationalWeeks: (map['gestational_weeks'] as num?)?.toInt(),
    createdAt: map['created_at'] as int,
  );
}
