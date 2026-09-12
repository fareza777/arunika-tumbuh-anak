import 'package:arunika_growth/domain/together/together_copy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('greeting follows the local hour', () {
    expect(greetingFor(DateTime(2026, 9, 12, 7)), 'Selamat pagi');
    expect(greetingFor(DateTime(2026, 9, 12, 13)), 'Selamat siang');
    expect(greetingFor(DateTime(2026, 9, 12, 17)), 'Selamat sore');
    expect(greetingFor(DateTime(2026, 9, 12, 21)), 'Selamat malam');
  });
}
