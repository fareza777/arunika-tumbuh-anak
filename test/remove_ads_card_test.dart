import 'dart:async';

import 'package:arunika_growth/domain/monetization/monetization_gateway.dart';
import 'package:arunika_growth/state/app_settings.dart';
import 'package:arunika_growth/state/monetization_provider.dart';
import 'package:arunika_growth/ui/monetization/remove_ads_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _UnavailableGateway implements MonetizationGateway {
  final _updates = StreamController<PurchaseUpdate>.broadcast();

  @override
  Stream<PurchaseUpdate> get purchaseUpdates => _updates.stream;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<MonetizationProduct?> queryRemoveAds() async => null;

  @override
  Future<void> restorePurchases() async {}

  @override
  Future<void> buyRemoveAds() async {}

  @override
  Future<void> showPrivacyOptions() async {}

  @override
  Future<void> dispose() => _updates.close();
}

void main() {
  testWidgets('purchase card shows its quiet-premium value clearly', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          monetizationGatewayProvider.overrideWithValue(_UnavailableGateway()),
        ],
        child: const MaterialApp(home: Scaffold(body: RemoveAdsCard())),
      ),
    );
    await tester.pump();

    expect(find.text('Tanpa banner'), findsOneWidget);
    expect(find.text('Sekali bayar'), findsOneWidget);
    expect(find.text('Pulihkan kapan saja'), findsOneWidget);
  });
}
