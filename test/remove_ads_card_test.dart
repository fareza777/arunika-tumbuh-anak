import 'dart:async';

import 'package:arunika_growth/core/theme/app_theme.dart';
import 'package:arunika_growth/domain/monetization/monetization_gateway.dart';
import 'package:arunika_growth/state/app_settings.dart';
import 'package:arunika_growth/state/monetization_provider.dart';
import 'package:arunika_growth/ui/monetization/remove_ads_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _CardGateway implements MonetizationGateway {
  final updates = StreamController<PurchaseUpdate>.broadcast();
  bool available = false;
  int buyCalls = 0;
  @override
  Stream<PurchaseUpdate> get purchaseUpdates => updates.stream;
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> isAvailable() async => available;
  @override
  Future<MonetizationProduct?> queryRemoveAds() async => available
      ? const MonetizationProduct(id: 'arunika_remove_ads', price: 'Rp79.000')
      : null;
  @override
  Future<void> restorePurchases() async {}
  @override
  Future<void> buyRemoveAds() async => buyCalls++;
  @override
  Future<void> showPrivacyOptions() async {}
  @override
  Future<void> dispose() => updates.close();
}

void main() {
  Future<_CardGateway> showCard(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    double scale = 1,
    bool available = false,
    bool purchased = false,
  }) async {
    tester.view.physicalSize = const Size(320, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'ads_removed_hint': purchased});
    final prefs = await SharedPreferences.getInstance();
    final gateway = _CardGateway()..available = available;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          monetizationGatewayProvider.overrideWithValue(gateway),
        ],
        child: MaterialApp(
          theme: AppTheme.build(brightness: brightness),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: const Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: RemoveAdsCard(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return gateway;
  }

  testWidgets('unavailable store shows no invented price or purchase action', (
    tester,
  ) async {
    await showCard(tester);
    expect(find.textContaining('US\$'), findsNothing);
    expect(find.textContaining('Beli sekali'), findsNothing);
    expect(find.text('Hubungkan ke Google Play'), findsOneWidget);
    expect(find.text('Pulihkan pembelian'), findsOneWidget);
  });

  testWidgets('reconnect fetches a localized price before enabling purchase', (
    tester,
  ) async {
    final gateway = await showCard(tester);
    gateway.available = true;
    await tester.tap(find.text('Hubungkan ke Google Play'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Rp79.000'), findsWidgets);
    expect(gateway.buyCalls, 0);
    await tester.tap(find.text('Beli sekali · Rp79.000'));
    await tester.pump();
    expect(gateway.buyCalls, 1);
  });

  for (final brightness in Brightness.values) {
    testWidgets('purchase and restore wrap at 320px and 2x in $brightness', (
      tester,
    ) async {
      await showCard(tester, brightness: brightness, scale: 2, available: true);
      expect(tester.takeException(), isNull);
      final buy = find.widgetWithText(FilledButton, 'Beli sekali · Rp79.000');
      final restore = find.widgetWithText(TextButton, 'Pulihkan pembelian');
      expect(tester.getSize(buy).height, greaterThanOrEqualTo(48));
      expect(tester.getSize(restore).height, greaterThanOrEqualTo(48));
      await tester.ensureVisible(restore);
      expect(tester.takeException(), isNull);
    });
    testWidgets(
      'active entitlement remains readable with large text in $brightness',
      (tester) async {
        await showCard(
          tester,
          brightness: brightness,
          scale: 2,
          purchased: true,
        );
        expect(find.text('Bebas Iklan Aktif'), findsOneWidget);
        expect(find.textContaining('Beli sekali'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
