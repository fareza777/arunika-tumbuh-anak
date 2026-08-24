/// Satu orang di lingkar keluarga Arunika.
class FamilyMember {
  const FamilyMember({
    required this.id,
    required this.name,
    this.role = 'family',
    this.colorKey = 'sunrise',
    this.photoPath,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String role;
  final String colorKey;
  final String? photoPath;
  final int createdAt;

  String get roleLabel {
    switch (role) {
      case 'parent':
        return 'Orang tua';
      case 'grandparent':
        return 'Kakek/nenek';
      case 'sibling':
        return 'Kakak/adik';
      default:
        return 'Keluarga';
    }
  }

  FamilyMember copyWith({
    String? name,
    String? role,
    String? colorKey,
    String? photoPath,
    bool clearPhoto = false,
  }) {
    return FamilyMember(
      id: id,
      name: name ?? this.name,
      role: role ?? this.role,
      colorKey: colorKey ?? this.colorKey,
      photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
      createdAt: createdAt,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'role': role,
    'color_key': colorKey,
    'photo_path': photoPath,
    'created_at': createdAt,
  };

  static FamilyMember fromMap(Map<String, Object?> map) => FamilyMember(
    id: map['id']! as String,
    name: map['name']! as String,
    role: (map['role'] as String?) ?? 'family',
    colorKey: (map['color_key'] as String?) ?? 'sunrise',
    photoPath: map['photo_path'] as String?,
    createdAt: map['created_at']! as int,
  );
}
