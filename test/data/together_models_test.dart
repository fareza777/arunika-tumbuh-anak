import 'package:flutter_test/flutter_test.dart';

import 'package:arunika_growth/data/models/family_member.dart';
import 'package:arunika_growth/data/models/moment.dart';
import 'package:arunika_growth/data/models/ritual.dart';

void main() {
  test('family member round-trips through SQLite map', () {
    const member = FamilyMember(
      id: 'member-1',
      name: 'Nara',
      role: 'parent',
      colorKey: 'terracotta',
      createdAt: 123,
    );

    expect(FamilyMember.fromMap(member.toMap()).name, 'Nara');
    expect(FamilyMember.fromMap(member.toMap()).roleLabel, 'Orang tua');
  });

  test('ritual serializes repeat days in stable order', () {
    final ritual = Ritual(
      id: 'ritual-1',
      title: 'Baca bersama',
      repeatDays: {7, 1, 4},
      timeOfDay: RitualTimeOfDay.evening,
      createdAt: 123,
    );

    final restored = Ritual.fromMap(ritual.toMap());
    expect(ritual.toMap()['repeat_days'], '1,4,7');
    expect(restored.timeOfDay, RitualTimeOfDay.evening);
    expect(restored.isScheduledFor(DateTime(2026, 8, 24)), isTrue);
  });

  test('moment preserves optional member and tag', () {
    final moment = Moment(
      id: 'moment-1',
      title: 'Hujan sore',
      note: 'Kami menari di teras.',
      tag: MomentTag.laugh,
      memberId: 'member-1',
      capturedAt: DateTime(2026, 8, 24),
      createdAt: 123,
    );

    final restored = Moment.fromMap(moment.toMap());
    expect(restored.tag, MomentTag.laugh);
    expect(restored.memberId, 'member-1');
    expect(restored.note, 'Kami menari di teras.');
  });
}
