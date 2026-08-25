import 'dart:async';

import 'package:arunika_growth/domain/monetization/monetization_gateway.dart';
import 'package:arunika_growth/state/app_settings.dart';
import 'package:arunika_growth/state/monetization_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeGateway implements MonetizationGateway {
  final updates = StreamController<PurchaseUpdate>.broadcast();
  var initialized = false;
  var buyCalls = 0;
  var restoreCalls = 0;
  var available = true;
  Object? buyError;

  @override
  Stream<PurchaseUpdate> get purchaseUpdates => updates.stream;

  @override
  Future<void> initialize() async => initialized = true;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<MonetizationProduct?> queryRemoveAds() async =>
      const MonetizationProduct(id: 'arunika_remove_ads', price: 'US\$4.99');

  @override
  Future<void> restorePurchases() async => restoreCalls++;

  @override
  Future<void> buyRemoveAds() async {
    buyCalls++;
    if (buyError != null) throw buyError!;
    updates.add(
      const PurchaseUpdate(
        productId: 'arunika_remove_ads',
        status: PurchaseUpdateStatus.purchased,
        price: 'US\$4.99',
      ),
    );
  }

  @override
  Future<void> showPrivacyOptions() async {}

  @override
  Future<void> dispose() => updates.close();

  void emit(PurchaseUpdate update) => updates.add(update);
}

void main() {
  late SharedPreferences prefs;
  late _FakeGateway gateway;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    gateway = _FakeGateway();
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        monetizationGatewayProvider.overrideWithValue(gateway),
      ],
    );
  }

  test(
    'controller starts with ads visible and verifies a restored purchase',
    () async {
      final container = createContainer();
      addTearDown(container.dispose);

      expect(container.read(monetizationProvider).adsRemoved, isFalse);
      await pumpEventQueue();
      expect(gateway.initialized, isTrue);

      gateway.emit(
        const PurchaseUpdate(
          productId: 'arunika_remove_ads',
          status: PurchaseUpdateStatus.restored,
        ),
      );
      await pumpEventQueue();

      expect(container.read(monetizationProvider).adsRemoved, isTrue);
    },
  );

  test('unrelated product purchase does not remove ads', () async {
    final container = createContainer();
    addTearDown(container.dispose);
    expect(container.read(monetizationProvider).adsRemoved, isFalse);
    await pumpEventQueue();

    gateway.emit(
      const PurchaseUpdate(
        productId: 'unrelated_product',
        status: PurchaseUpdateStatus.purchased,
      ),
    );
    await pumpEventQueue();

    expect(container.read(monetizationProvider).adsRemoved, isFalse);
  });

  test('billing error preserves a previously verified entitlement', () async {
    final container = createContainer();
    addTearDown(container.dispose);
    expect(container.read(monetizationProvider).adsRemoved, isFalse);
    await pumpEventQueue();
    gateway.emit(
      const PurchaseUpdate(
        productId: 'arunika_remove_ads',
        status: PurchaseUpdateStatus.purchased,
      ),
    );
    await pumpEventQueue();
    gateway.emit(
      const PurchaseUpdate(
        productId: 'arunika_remove_ads',
        status: PurchaseUpdateStatus.error,
        errorMessage: 'offline',
      ),
    );
    await pumpEventQueue();

    final state = container.read(monetizationProvider);
    expect(state.adsRemoved, isTrue);
    expect(state.message, 'offline');
  });

  test('buy and restore delegate to the gateway', () async {
    final container = createContainer();
    addTearDown(container.dispose);
    await pumpEventQueue();

    await container.read(monetizationProvider.notifier).buyRemoveAds();
    await container.read(monetizationProvider.notifier).restorePurchases();

    expect(gateway.buyCalls, 1);
    expect(gateway.restoreCalls, 1);
  });

  test('buy failure exits checking state with a message', () async {
    gateway.available = false;
    gateway.buyError = StateError('Pembelian belum tersedia');
    final container = createContainer();
    addTearDown(container.dispose);

    await container.read(monetizationProvider.notifier).buyRemoveAds();

    final state = container.read(monetizationProvider);
    expect(state.isVerifying, isFalse);
    expect(state.message, 'Pembelian belum tersedia');
  });
}
