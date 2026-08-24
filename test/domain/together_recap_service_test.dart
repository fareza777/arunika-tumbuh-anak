import 'package:flutter_test/flutter_test.dart';

import 'package:arunika_growth/data/models/moment.dart';
import 'package:arunika_growth/data/models/ritual.dart';
import 'package:arunika_growth/data/models/ritual_check_in.dart';
import 'package:arunika_growth/domain/together/recap_service.dart';

void main() {
  test('weekly recap is deterministic and ignores older entries', () {
    final now = DateTime(2026, 8, 24);
    final recap = RecapService.build(
      now: now,
      rituals: [Ritual(id: 'r1', title: 'Baca', createdAt: 1)],
      moments: [
        Moment(
          id: 'm1',
          title: 'Pagi',
          note: 'Matahari.',
          tag: MomentTag.gratitude,
          capturedAt: DateTime(2026, 8, 23),
          createdAt: 1,
        ),
        Moment(
          id: 'old',
          title: 'Lama',
          note: 'Bulan lalu.',
          capturedAt: DateTime(2026, 7, 1),
          createdAt: 1,
        ),
      ],
      checkIns: [
        RitualCheckIn(ritualId: 'r1', dayKey: '2026-08-23', completedAt: now),
      ],
    );

    expect(recap.momentCount, 1);
    expect(recap.ritualCount, 1);
    expect(recap.topTag, MomentTag.gratitude);
    expect(recap.activeDays, 1);
    expect(recap.cards, isNotEmpty);
  });

  test('empty recap still gives a useful next-step card', () {
    final recap = RecapService.build(
      now: DateTime(2026, 8, 24),
      rituals: const [],
      moments: const [],
      checkIns: const [],
    );

    expect(recap.momentCount, 0);
    expect(recap.ritualCount, 0);
    expect(recap.cards.first.title, 'Ada ruang untuk cerita baru');
  });
}
