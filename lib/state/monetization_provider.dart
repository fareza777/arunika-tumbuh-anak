import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/monetization/interstitial_gate.dart';
import '../domain/monetization/monetization_config.dart';
import '../domain/monetization/monetization_gateway.dart';
import '../domain/monetization/monetization_service.dart';
import '../domain/monetization/monetization_state.dart';
import 'app_settings.dart';

final monetizationGatewayProvider = Provider<MonetizationGateway>(
  (ref) => MonetizationService(),
);

final monetizationProvider =
    NotifierProvider<MonetizationController, MonetizationState>(
      MonetizationController.new,
    );

class MonetizationController extends Notifier<MonetizationState> {
  static const _entitlementHintKey = 'ads_removed_hint';

  late MonetizationGateway _gateway;
  late StreamSubscription<PurchaseUpdate> _purchaseSubscription;
  final interstitialGate = InterstitialGate();
  var _disposed = false;

  @override
  MonetizationState build() {
    _gateway = ref.read(monetizationGatewayProvider);
    _purchaseSubscription = _gateway.purchaseUpdates.listen(_handlePurchase);
    ref.onDispose(() {
      _disposed = true;
      unawaited(_purchaseSubscription.cancel());
      unawaited(_gateway.dispose());
    });
    unawaited(_initialize());
    return const MonetizationState.initial();
  }

  Future<void> _initialize() async {
    try {
      await _gateway.initialize();
      if (_disposed) return;

      if (!await _gateway.isAvailable()) {
        state = state.copyWith(isVerifying: false);
        return;
      }

      final product = await _gateway.queryRemoveAds();
      if (_disposed) return;
      state = state.copyWith(
        storeAvailable: product != null,
        productPrice: product?.price,
        clearMessage: true,
      );

      await _gateway.restorePurchases();
      if (_disposed || state.adsRemoved) return;
      state = state.copyWith(isVerifying: false);
    } catch (error) {
      if (_disposed) return;
      state = state.withMessage(_friendlyError(error));
    }
  }

  Future<void> buyRemoveAds() async {
    state = state.copyWith(isVerifying: true, clearMessage: true);
    try {
      await _gateway.buyRemoveAds();
    } catch (error) {
      if (!_disposed) state = state.withMessage(_friendlyError(error));
    }
  }

  Future<void> restorePurchases() async {
    state = state.copyWith(isVerifying: true, clearMessage: true);
    try {
      await _gateway.restorePurchases();
      if (!_disposed && !state.adsRemoved) {
        state = state.copyWith(isVerifying: false);
      }
    } catch (error) {
      if (!_disposed) state = state.withMessage(_friendlyError(error));
    }
  }

  void onMeasurementSaved() {
    interstitialGate.recordMeasurementSaved();
  }

  void _handlePurchase(PurchaseUpdate update) {
    if (_disposed ||
        update.productId != MonetizationConfig.removeAdsProductId) {
      return;
    }

    switch (update.status) {
      case PurchaseUpdateStatus.purchased:
      case PurchaseUpdateStatus.restored:
        state = state.verified(price: update.price ?? state.productPrice);
        unawaited(
          ref.read(sharedPrefsProvider).setBool(_entitlementHintKey, true),
        );
      case PurchaseUpdateStatus.pending:
        state = state.copyWith(isVerifying: true);
      case PurchaseUpdateStatus.canceled:
        state = state.copyWith(isVerifying: false);
      case PurchaseUpdateStatus.error:
        state = state.withMessage(update.errorMessage ?? 'Pembelian gagal.');
    }
  }

  String _friendlyError(Object error) {
    final text = error.toString().replaceFirst('Exception: ', '');
    return text.isEmpty ? 'Play Store sementara tidak tersedia.' : text;
  }
}
