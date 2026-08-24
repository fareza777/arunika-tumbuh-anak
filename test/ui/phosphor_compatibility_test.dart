import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

void main() {
  test('icon facade exposes the API used by the app', () {
    expect(PhosphorIconsLight.sun, isA<IconData>());
    expect(PhosphorIconsFill.images, isA<IconData>());
    expect(const PhosphorIcon(PhosphorIconsLight.sparkle), isA<Widget>());
  });
}
