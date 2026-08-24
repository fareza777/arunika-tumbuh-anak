class RitualCheckIn {
  const RitualCheckIn({
    required this.ritualId,
    required this.dayKey,
    required this.completedAt,
  });

  final String ritualId;
  final String dayKey;
  final DateTime completedAt;

  Map<String, Object?> toMap() => {
    'ritual_id': ritualId,
    'day_key': dayKey,
    'completed_at': completedAt.millisecondsSinceEpoch,
  };

  static RitualCheckIn fromMap(Map<String, Object?> map) => RitualCheckIn(
    ritualId: map['ritual_id']! as String,
    dayKey: map['day_key']! as String,
    completedAt: DateTime.fromMillisecondsSinceEpoch(
      map['completed_at']! as int,
    ),
  );
}
