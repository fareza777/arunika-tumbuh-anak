enum MomentTag {
  laugh,
  learn,
  together,
  brave,
  gratitude;

  String get label {
    switch (this) {
      case MomentTag.laugh:
        return 'Tawa';
      case MomentTag.learn:
        return 'Belajar';
      case MomentTag.together:
        return 'Bersama';
      case MomentTag.brave:
        return 'Berani';
      case MomentTag.gratitude:
        return 'Syukur';
    }
  }

  static MomentTag fromString(String value) => MomentTag.values.firstWhere(
    (item) => item.name == value,
    orElse: () => together,
  );
}

/// Catatan kecil tentang hari yang ingin diingat kembali.
class Moment {
  const Moment({
    required this.id,
    required this.title,
    required this.note,
    this.tag = MomentTag.together,
    this.memberId,
    this.photoPath,
    required this.capturedAt,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String note;
  final MomentTag tag;
  final String? memberId;
  final String? photoPath;
  final DateTime capturedAt;
  final int createdAt;

  Moment copyWith({
    String? title,
    String? note,
    MomentTag? tag,
    String? memberId,
    String? photoPath,
    DateTime? capturedAt,
    bool clearMember = false,
    bool clearPhoto = false,
  }) {
    return Moment(
      id: id,
      title: title ?? this.title,
      note: note ?? this.note,
      tag: tag ?? this.tag,
      memberId: clearMember ? null : (memberId ?? this.memberId),
      photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
      capturedAt: capturedAt ?? this.capturedAt,
      createdAt: createdAt,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'note': note,
    'tag': tag.name,
    'member_id': memberId,
    'photo_path': photoPath,
    'captured_at': capturedAt.millisecondsSinceEpoch,
    'created_at': createdAt,
  };

  static Moment fromMap(Map<String, Object?> map) => Moment(
    id: map['id']! as String,
    title: map['title']! as String,
    note: map['note']! as String,
    tag: MomentTag.fromString((map['tag'] as String?) ?? 'together'),
    memberId: map['member_id'] as String?,
    photoPath: map['photo_path'] as String?,
    capturedAt: DateTime.fromMillisecondsSinceEpoch(map['captured_at']! as int),
    createdAt: map['created_at']! as int,
  );
}
