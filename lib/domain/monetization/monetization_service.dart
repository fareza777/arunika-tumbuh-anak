import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'monetization_config.dart';
import 'monetization_gateway.dart';

/// The concrete bridge to Google Mobile Ads and Google Play Billing.
class MonetizationService implements MonetizationGateway {
  MonetizationService({MonetizationConfig? config})
    : _config = config ?? MonetizationConfig.fromEnvironment();

  final MonetizationConfig _config;
  final InAppPurchase _store = InAppPurchase.instance;
  final _updates = StreamController<PurchaseUpdate>.broadcast();
  final _products = <String, ProductDetails>{};
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  var _initialized = false;

  @override
  Stream<PurchaseUpdate> get purchaseUpdates => _updates.stream;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if ((!_config.isRelease || _config.isValidForRelease) &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      // Consent must be resolved before the first ad request. If the UMP
      // service is unavailable or the user has not completed the required
      // choice, the banner slot remains visible but no ad request is made.
      if (await _prepareAdConsent()) {
        await MobileAds.instance.initialize();
      }
    }

    _purchaseSubscription = _store.purchaseStream.listen(
      (purchases) => unawaited(_handlePurchases(purchases)),
      onError: (Object error) {
        _updates.add(
          PurchaseUpdate(
            productId: _config.productId,
            status: PurchaseUpdateStatus.error,
            errorMessage: error.toString(),
          ),
        );
      },
    );
  }

  @override
  Future<bool> isAvailable() => _store.isAvailable();

  @override
  Future<MonetizationProduct?> queryRemoveAds() async {
    final response = await _store.queryProductDetails({_config.productId});
    if (response.productDetails.isEmpty) return null;

    final product = response.productDetails.firstWhere(
      (item) => item.id == _config.productId,
      orElse: () => response.productDetails.first,
    );
    _products[product.id] = product;
    return MonetizationProduct(id: product.id, price: product.price);
  }

  @override
  Future<void> restorePurchases() => _store.restorePurchases();

  @override
  Future<void> buyRemoveAds() async {
    var product = _products[_config.productId];
    if (product == null) {
      await queryRemoveAds();
      product = _products[_config.productId];
    }
    if (product == null) {
      throw StateError(
        'Produk ${_config.productId} belum tersedia di Play Store.',
      );
    }
    await _store.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );
  }

  @override
  Future<void> showPrivacyOptions() async {
    final mobile =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    if (!mobile) return;

    final completed = Completer<FormError?>();
    try {
      await ConsentForm.showPrivacyOptionsForm((error) {
        if (!completed.isCompleted) completed.complete(error);
      });
      final error = await completed.future.timeout(const Duration(seconds: 8));
      if (error != null) throw StateError(error.message);
    } catch (error) {
      if (error is StateError) rethrow;
      throw StateError('Opsi privasi iklan belum tersedia.');
    }
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      final status = switch (purchase.status) {
        PurchaseStatus.pending => PurchaseUpdateStatus.pending,
        PurchaseStatus.purchased => PurchaseUpdateStatus.purchased,
        PurchaseStatus.restored => PurchaseUpdateStatus.restored,
        PurchaseStatus.canceled => PurchaseUpdateStatus.canceled,
        PurchaseStatus.error => PurchaseUpdateStatus.error,
      };

      _updates.add(
        PurchaseUpdate(
          productId: purchase.productID,
          status: status,
          errorMessage: purchase.error?.message,
        ),
      );

      if (purchase.pendingCompletePurchase &&
          (purchase.status == PurchaseStatus.purchased ||
              purchase.status == PurchaseStatus.restored ||
              purchase.status == PurchaseStatus.error)) {
        try {
          await _store.completePurchase(purchase);
        } catch (_) {
          // The purchase remains visible in the next stream delivery and can
          // be completed again; never revoke a verified entitlement here.
        }
      }
    }
  }

  Future<bool> _prepareAdConsent() async {
    final information = ConsentInformation.instance;
    final completed = Completer<void>();

    void finish() {
      if (!completed.isCompleted) completed.complete();
    }

    try {
      information.requestConsentInfoUpdate(
        ConsentRequestParameters(tagForUnderAgeOfConsent: false),
        () => unawaited(_showConsentFormIfRequired(finish)),
        (error) {
          debugPrint('Arunika consent update: ${error.message}');
          finish();
        },
      );
      await completed.future.timeout(const Duration(seconds: 8));
    } catch (error) {
      debugPrint('Arunika consent unavailable: $error');
      finish();
    }

    try {
      return await information.canRequestAds();
    } catch (error) {
      debugPrint('Arunika consent status unavailable: $error');
      return false;
    }
  }

  Future<void> _showConsentFormIfRequired(void Function() onFinished) async {
    try {
      await ConsentForm.loadAndShowConsentFormIfRequired((error) {
        if (error != null) {
          debugPrint('Arunika consent form: ${error.message}');
        }
      });
    } finally {
      onFinished();
    }
  }

  @override
  Future<void> dispose() async {
    await _purchaseSubscription?.cancel();
    await _updates.close();
  }
}
