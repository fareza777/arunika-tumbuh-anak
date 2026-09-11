import 'package:arunika_growth/data/models/moment.dart';
import 'package:arunika_growth/domain/together/recap_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'weekly reflection excludes future memories and never exceeds seven days',
    () {
      final today = DateTime(2026, 9, 5);
      final moments = List.generate(
        15,
        (i) => Moment(
          id: '$i',
          title: 'Story $i',
          note: 'Saved story',
          capturedAt: DateTime(2026, 9, i + 1),
          createdAt: 0,
        ),
      );
      final recap = RecapService.build(
        moments: moments,
        checkIns: [],
        rituals: [],
        now: today,
      );
      expect(recap.momentCount, 5);
      expect(recap.activeDays, 5);
    },
  );
}
