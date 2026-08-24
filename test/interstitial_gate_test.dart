import 'package:arunika_growth/domain/monetization/interstitial_gate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('interstitial becomes eligible after three successful saves', () {
    final gate = InterstitialGate();
    final now = DateTime(2026, 8, 24, 10);

    expect(gate.canShow(now), isFalse);
    gate.recordMeasurementSaved();
    gate.recordMeasurementSaved();
    gate.recordMeasurementSaved();

    expect(gate.canShow(now), isTrue);
  });

  test('one show is allowed per measurement cycle', () {
    final gate = InterstitialGate();
    final now = DateTime(2026, 8, 24, 10);
    for (var i = 0; i < 3; i++) {
      gate.recordMeasurementSaved();
    }

    expect(gate.canShow(now), isTrue);
    gate.recordShown(now);
    expect(gate.canShow(now.add(const Duration(minutes: 30))), isFalse);
  });

  test('cooldown blocks the next cycle for ten minutes', () {
    final gate = InterstitialGate();
    final now = DateTime(2026, 8, 24, 10);
    for (var i = 0; i < 3; i++) {
      gate.recordMeasurementSaved();
    }
    gate.recordShown(now);
    for (var i = 0; i < 3; i++) {
      gate.recordMeasurementSaved();
    }

    expect(gate.canShow(now.add(const Duration(minutes: 9, seconds: 59))), isFalse);
    expect(gate.canShow(now.add(const Duration(minutes: 10))), isTrue);
  });
}
