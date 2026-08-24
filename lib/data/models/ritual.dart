enum RitualTimeOfDay {
  morning,
  afternoon,
  evening,
  anytime;

  String get label {
    switch (this) {
      case RitualTimeOfDay.morning:
        return 'Pagi';
      case RitualTimeOfDay.afternoon:
        return 'Sore';
      case RitualTimeOfDay.evening:
        return 'Malam';
      case RitualTimeOfDay.anytime:
        return 'Kapan saja';
    }
  }

  String get prompt {
    switch (this) {
      case RitualTimeOfDay.morning:
        return 'Buka hari dengan pelan';
      case RitualTimeOfDay.afternoon:
        return 'Jeda kecil untuk bersama';
      case RitualTimeOfDay.evening:
        return 'Tutup hari dengan hangat';
      case RitualTimeOfDay.anytime:
        return 'Temukan waktu yang terasa pas';
    }
  }

  static RitualTimeOfDay fromString(String value) => RitualTimeOfDay.values
      .firstWhere((item) => item.name == value, orElse: () => anytime);
}

String ritualDayKey(DateTime date) {
  final local = DateTime(date.year, date.month, date.day);
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}

/// Kebiasaan kecil yang bisa dirayakan berulang bersama keluarga.
class Ritual {
  const Ritual({
    required this.id,
    required this.title,
    this.description,
    this.timeOfDay = RitualTimeOfDay.anytime,
    this.repeatDays = const {1, 2, 3, 4, 5, 6, 7},
    this.accentKey = 'sage',
    this.isArchived = false,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String? description;
  final RitualTimeOfDay timeOfDay;
  final Set<int> repeatDays;
  final String accentKey;
  final bool isArchived;
  final int createdAt;

  bool isScheduledFor(DateTime date) => repeatDays.contains(date.weekday);

  String get repeatDaysCsv => (repeatDays.toList()..sort()).join(',');

  Ritual copyWith({
    String? title,
    String? description,
    RitualTimeOfDay? timeOfDay,
    Set<int>? repeatDays,
    String? accentKey,
    bool? isArchived,
  }) {
    return Ritual(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      repeatDays: repeatDays ?? this.repeatDays,
      accentKey: accentKey ?? this.accentKey,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'time_of_day': timeOfDay.name,
    'repeat_days': repeatDaysCsv,
    'accent_key': accentKey,
    'is_archived': isArchived ? 1 : 0,
    'created_at': createdAt,
  };

  static Ritual fromMap(Map<String, Object?> map) {
    final days = ((map['repeat_days'] as String?) ?? '1,2,3,4,5,6,7')
        .split(',')
        .map(int.tryParse)
        .whereType<int>()
        .where((day) => day >= 1 && day <= 7)
        .toSet();
    return Ritual(
      id: map['id']! as String,
      title: map['title']! as String,
      description: map['description'] as String?,
      timeOfDay: RitualTimeOfDay.fromString(
        (map['time_of_day'] as String?) ?? 'anytime',
      ),
      repeatDays: days.isEmpty ? const {1, 2, 3, 4, 5, 6, 7} : days,
      accentKey: (map['accent_key'] as String?) ?? 'sage',
      isArchived: (map['is_archived'] as num?) == 1,
      createdAt: map['created_at']! as int,
    );
  }
}
