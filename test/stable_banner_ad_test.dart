import 'package:arunika_growth/ui/monetization/stable_banner_ad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('banner slot reserves height while loading', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StableBannerSlot(
            placement: BannerPlacement.mainShell,
            adsRemoved: false,
          ),
        ),
      ),
    );

    final slot = find.byKey(const ValueKey('banner-slot:mainShell'));
    expect(tester.getSize(slot).height, greaterThan(0));
  });

  testWidgets('banner slot keeps the same height after an ad load error', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StableBannerSlot(
            placement: BannerPlacement.mainShell,
            adsRemoved: false,
            hasError: true,
          ),
        ),
      ),
    );

    final slot = find.byKey(const ValueKey('banner-slot:mainShell'));
    expect(tester.getSize(slot).height, 54);
    expect(find.text('Iklan akan dimuat kembali'), findsOneWidget);
  });

  testWidgets('banner slot shrinks only after a verified entitlement', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StableBannerSlot(
            placement: BannerPlacement.mainShell,
            adsRemoved: true,
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('banner-slot:mainShell')), findsNothing);
    expect(tester.getSize(find.byType(Scaffold)).height, greaterThan(0));
  });
}
