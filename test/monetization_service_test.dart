import 'dart:async';

import 'package:arunika_growth/domain/monetization/monetization_config.dart';
import 'package:arunika_growth/domain/monetization/monetization_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class _Store extends Fake implements InAppPurchase {
  final purchases = StreamController<List<PurchaseDetails>>.broadcast();
  final completeGate = Completer<void>();
  var purchaseAccepted = true;
  @override
  Stream<List<PurchaseDetails>> get purchaseStream => purchases.stream;
  @override
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> identifiers,
  ) async => ProductDetailsResponse(
    productDetails: [
      ProductDetails(
        id: 'arunika_remove_ads',
        title: 'Bebas iklan',
        description: 'Sekali bayar',
        price: 'Rp79.000',
        rawPrice: 79000,
        currencyCode: 'IDR',
      ),
    ],
    notFoundIDs: const [],
  );
  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async =>
      purchaseAccepted;
  @override
  Future<void> completePurchase(PurchaseDetails purchase) =>
      completeGate.future;
}

void main() {
  const config = MonetizationConfig(
    productId: 'arunika_remove_ads',
    admobAppId: '',
    bannerAdUnitId: '',
    interstitialAdUnitId: '',
    isRelease: true,
  );
  test(
    'rejected launch reports a recoverable error instead of waiting forever',
    () async {
      final store = _Store()..purchaseAccepted = false;
      final service = MonetizationService(config: config, store: store);
      addTearDown(service.dispose);
      addTearDown(store.purchases.close);
      await service.initialize();
      await expectLater(service.buyRemoveAds(), throwsStateError);
    },
  );
  test(
    'disposing during acknowledgement stops late batch events safely',
    () async {
      final store = _Store();
      final service = MonetizationService(config: config, store: store);
      final received = [];
      final subscription = service.purchaseUpdates.listen(received.add);
      await service.initialize();
      final first = PurchaseDetails(
        productID: 'arunika_remove_ads',
        status: PurchaseStatus.purchased,
        verificationData: PurchaseVerificationData(
          localVerificationData: '',
          serverVerificationData: '',
          source: 'google_play',
        ),
        transactionDate: '1000',
      )..pendingCompletePurchase = true;
      final second = PurchaseDetails(
        productID: 'arunika_remove_ads',
        status: PurchaseStatus.restored,
        verificationData: PurchaseVerificationData(
          localVerificationData: '',
          serverVerificationData: '',
          source: 'google_play',
        ),
        transactionDate: '1001',
      );
      store.purchases.add([first, second]);
      await pumpEventQueue();
      await service.dispose();
      store.completeGate.complete();
      await pumpEventQueue();
      expect(received, hasLength(1));
      await subscription.cancel();
      await store.purchases.close();
    },
  );
}
