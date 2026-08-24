/// Satu catatan pengukuran antropometri anak.
class Measurement {
  const Measurement({
    required this.id,
    required this.childId,
    required this.date,
    this.weight,
    this.height,
    this.head,
    this.muac,
    this.note,
    required this.createdAt,
  });

  final String id;
  final String childId;
  final DateTime date;

  final double? weight; // kg
  final double? height; // cm (panjang badan < 2 th, tinggi >= 2 th)
  final double? head; // lingkar kepala cm
  final double? muac; // lingkar lengan atas cm

  final String? note;
  final int createdAt;

  /// Indeks Massa Tubuh (kg/m²).
  double? get bmi {
    if (weight == null || height == null || height == 0) return null;
    final m = height! / 100;
    return weight! / (m * m);
  }

  bool get hasAnthropometry => weight != null || height != null || head != null;

  Measurement copyWith({
    DateTime? date,
    double? weight,
    double? height,
    double? head,
    double? muac,
    String? note,
  }) {
    return Measurement(
      id: id,
      childId: childId,
      date: date ?? this.date,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      head: head ?? this.head,
      muac: muac ?? this.muac,
      note: note ?? this.note,
      createdAt: createdAt,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'child_id': childId,
    'date': date.millisecondsSinceEpoch,
    'weight': weight,
    'height': height,
    'head': head,
    'muac': muac,
    'note': note,
    'created_at': createdAt,
  };

  static Measurement fromMap(Map<String, Object?> map) => Measurement(
    id: map['id'] as String,
    childId: map['child_id'] as String,
    date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
    weight: (map['weight'] as num?)?.toDouble(),
    height: (map['height'] as num?)?.toDouble(),
    head: (map['head'] as num?)?.toDouble(),
    muac: (map['muac'] as num?)?.toDouble(),
    note: map['note'] as String?,
    createdAt: map['created_at'] as int,
  );
}
