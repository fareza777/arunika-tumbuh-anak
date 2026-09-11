import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/monetization/interstitial_ad_manager.dart';
import '../domain/monetization/interstitial_gate.dart';
import '../domain/monetization/monetization_config.dart';
import '../domain/monetization/monetization_gateway.dart';
import '../domain/monetization/monetization_service.dart';
import '../domain/monetization/monetization_state.dart';
import '../domain/monetization/rewarded_ad_manager.dart';
import 'app_settings.dart';

final monetizationGatewayProvider = Provider<MonetizationGateway>(
  (ref) => MonetizationService(),
);

final monetizationClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

final rewardedAdManagerProvider = Provider<RewardedAdManager>(
  (ref) => RewardedAdManager(),
);

final interstitialAdManagerFactoryProvider =
    Provider<InterstitialAdManager Function()>(
      (ref) =>
          () => InterstitialAdManager(now: ref.read(monetizationClockProvider)),
    );

final monetizationProvider =
    NotifierProvider<MonetizationController, MonetizationState>(
      MonetizationController.new,
    );

class MonetizationController extends Notifier<MonetizationState> {
  static const _entitlementHintKey = 'ads_removed_hint';
  static const _adPauseKey = 'rewarded_ad_pause_until';
  static const rewardedPauseDuration = Duration(minutes: 30);
  static const _unavailableMessage =
      'Google Play belum tersedia. Periksa koneksi internet, lalu hubungkan kembali.';
  static const _productUnavailableMessage =
      'Produk Bebas Iklan belum tersedia di Google Play. Coba hubungkan kembali nanti.';

  late MonetizationGateway _gateway;
  late RewardedAdManager _rewardedManager;
  late DateTime Function() _now;
  late StreamSubscription<PurchaseUpdate> _purchaseSubscription;
  InterstitialAdManager? _interstitialManager;
  Timer? _pauseTimer;
  Future<void> _pausePersistence = Future<void>.value();
  Future<void>? _connection;
  final interstitialGate = InterstitialGate();
  var _disposed = false;
  var _waitingForPurchase = false;

  @override
  MonetizationState build() {
    _gateway = ref.read(monetizationGatewayProvider);
    _rewardedManager = ref.read(rewardedAdManagerProvider);
    _now = ref.read(monetizationClockProvider);
    _purchaseSubscription = _gateway.purchaseUpdates.listen(
      _handlePurchase,
      onError: (Object error) {
        if (!_disposed) state = state.withMessage(_friendlyError(error));
      },
    );
    ref.onDispose(() {
      _disposed = true;
      _pauseTimer?.cancel();
      unawaited(_purchaseSubscription.cancel());
      unawaited(_gateway.dispose());
      unawaited(_interstitialManager?.dispose());
      unawaited(_rewardedManager.dispose());
    });
    _connection = _loadStore();
    unawaited(_connection);
    // Keep a previously verified local entitlement visible while Play checks
    // it. Temporary store errors never revoke an existing purchase.
    final pauseUntil = _readSavedPause();
    if (pauseUntil != null) _armPauseTimer(pauseUntil);
    return const MonetizationState.initial().copyWith(
      adsRemoved:
          ref.read(sharedPrefsProvider).getBool(_entitlementHintKey) == true,
      adPauseUntil: pauseUntil,
      adPauseMinutesRemaining: _remainingMinutes(pauseUntil),
      rewardedAvailable: _rewardedManager.isConfigured,
    );
  }

  Future<void> reconnectStore() async {
    if (_disposed || _waitingForPurchase) return;
    final current = _connection;
    if (current != null) return current;
    state = state.copyWith(isVerifying: true, clearMessage: true);
    _connection = _loadStore();
    await _connection;
  }

  Future<void> _loadStore() async {
    try {
      await _gateway.initialize();
      if (_disposed) return;
      final available = await _gateway.isAvailable();
      if (_disposed) return;
      if (!available) {
        _storeUnavailable(_unavailableMessage);
        return;
      }

      try {
        final product = await _gateway.queryRemoveAds();
        if (_disposed) return;
        if (product == null || product.price.trim().isEmpty) {
          _storeUnavailable(_productUnavailableMessage);
        } else {
          state = state.copyWith(
            storeAvailable: true,
            productPrice: product.price,
            clearMessage: true,
          );
        }
      } catch (error) {
        if (_disposed) return;
        _storeUnavailable(_friendlyError(error));
      }

      // Restoration must still run if product metadata is temporarily absent.
      await _gateway.restorePurchases();
      if (_disposed) return;
      state = state.copyWith(isVerifying: _waitingForPurchase);
    } catch (error) {
      if (_disposed) return;
      state = state.withMessage(_friendlyError(error));
    } finally {
      _connection = null;
    }
  }

  void _storeUnavailable(String message) {
    state = state.copyWith(
      isVerifying: false,
      storeAvailable: false,
      clearProductPrice: true,
      message: message,
    );
  }

  Future<void> buyRemoveAds() async {
    await _connection;
    if (_disposed || state.isVerifying || state.adsRemoved) return;
    if (!state.storeAvailable || (state.productPrice?.trim().isEmpty ?? true)) {
      state = state.withMessage(_productUnavailableMessage);
      return;
    }
    state = state.copyWith(
      isVerifying: true,
      message: 'Membuka pembayaran di Google Play…',
    );
    try {
      await _gateway.buyRemoveAds();
    } catch (error) {
      if (_disposed) return;
      _waitingForPurchase = false;
      state = state.withMessage(_friendlyError(error));
    }
  }

  Future<void> restorePurchases() async {
    await _connection;
    if (_disposed || _waitingForPurchase) return;
    state = state.copyWith(
      isVerifying: true,
      message: 'Memulihkan pembelian dari Google Play…',
    );
    try {
      final available = await _gateway.isAvailable();
      if (_disposed) return;
      if (!available) {
        _storeUnavailable(_unavailableMessage);
        return;
      }
      await _gateway.restorePurchases();
      if (_disposed) return;
      state = state.copyWith(
        isVerifying: _waitingForPurchase,
        message: state.adsRemoved
            ? null
            : 'Pemulihan diminta. Pastikan akun Google Play sama dengan akun saat membeli.',
        clearMessage: state.adsRemoved,
      );
    } catch (error) {
      if (!_disposed) state = state.withMessage(_friendlyError(error));
    }
  }

  Future<void> showPrivacyOptions() async {
    if (_disposed) return;
    try {
      await _gateway.showPrivacyOptions();
      if (_disposed) return;
      _suspendInterstitial();
      state = state.copyWith(adConsentRevision: state.adConsentRevision + 1);
    } catch (error) {
      if (!_disposed) state = state.withMessage(_friendlyError(error));
      rethrow;
    }
  }

  /// Call only after a successful moment save has returned to browsing.
  /// The route predicate must also reject a subsequent editor/tab change.
  Future<bool> onMomentSavedAndReturned({
    required bool Function() canPresent,
  }) async {
    if (_disposed) return false;
    refreshAdPause();
    if (state.adsSuppressed || state.isRewardedBusy || !canPresent()) {
      return false;
    }
    interstitialGate.recordMeaningfulSave();
    _interstitialManager ??= ref.read(interstitialAdManagerFactoryProvider)();
    return _interstitialManager!.showIfEligible(
      gate: interstitialGate,
      adsRemoved: state.adsSuppressed,
      canPresent: canPresent,
      adsSuppressed: () =>
          _disposed || state.adsSuppressed || state.isRewardedBusy,
    );
  }

  // Inactive legacy screens retain their API, but cannot create an ad
  // placement inside an editor. Only the completion hook above can present.
  void onMeasurementSaved() {}
  void onMeaningfulSave() {}
  Future<void> maybeShowInterstitial() async {}

  Future<void> watchRewardedBreak({required bool Function() canPresent}) async {
    if (_disposed) return;
    refreshAdPause();
    if (state.adsSuppressed || state.isRewardedBusy) return;
    if (!_rewardedManager.isConfigured) {
      state = state.copyWith(
        rewardedMessage: 'Iklan untuk jeda belum tersedia saat ini.',
      );
      return;
    }
    state = state.copyWith(
      isRewardedBusy: true,
      rewardedMessage: 'Memuat iklan pilihan Anda…',
    );
    final result = await _rewardedManager.show(
      canPresent: () => !_disposed && !state.adsSuppressed && canPresent(),
      onEarned: _grantAdPause,
    );
    if (_disposed) return;
    state = state.copyWith(
      isRewardedBusy: false,
      rewardedMessage: switch (result) {
        RewardedAdResult.earned =>
          state.rewardedMessage ?? 'Jeda bebas iklan aktif selama 30 menit.',
        RewardedAdResult.dismissed =>
          'Iklan ditutup sebelum hadiah diperoleh. Jeda belum diaktifkan.',
        RewardedAdResult.unavailable =>
          'Iklan belum tersedia. Periksa koneksi, lalu coba lagi nanti.',
        RewardedAdResult.canceled =>
          'Permintaan iklan dibatalkan. Jeda belum diaktifkan.',
      },
    );
  }

  void _grantAdPause() {
    if (_disposed || state.adsRemoved || state.adPauseUntil != null) return;
    final until = _now().add(rewardedPauseDuration);
    state = state.copyWith(
      adPauseUntil: until,
      adPauseMinutesRemaining: 30,
      rewardedMessage: 'Jeda bebas iklan aktif selama 30 menit.',
    );
    _suspendInterstitial();
    _armPauseTimer(until);
    _rememberPause(until);
  }

  /// Refresh on app resume as well as the timer: background suspension must
  /// not keep an expired pause visible or restart its 30-minute duration.
  void refreshAdPause() {
    if (_disposed) return;
    final until = state.adPauseUntil;
    if (until == null) return;
    if (!until.isAfter(_now())) {
      _pauseTimer?.cancel();
      state = state.copyWith(
        clearAdPause: true,
        rewardedMessage: 'Jeda bebas iklan telah selesai.',
      );
      _rememberPause(null);
      return;
    }
    state = state.copyWith(adPauseMinutesRemaining: _remainingMinutes(until));
    _armPauseTimer(until);
  }

  DateTime? _readSavedPause() {
    try {
      final value = ref.read(sharedPrefsProvider).getInt(_adPauseKey);
      if (value == null) return null;
      final until = DateTime.fromMillisecondsSinceEpoch(value);
      final now = _now();
      if (!until.isAfter(now) ||
          until.isAfter(now.add(rewardedPauseDuration))) {
        return null;
      }
      return until;
    } catch (_) {
      return null;
    }
  }

  int _remainingMinutes(DateTime? until) => until == null
      ? 0
      : (until.difference(_now()).inMilliseconds / 60000).ceil().clamp(1, 30);

  void _armPauseTimer(DateTime until) {
    _pauseTimer?.cancel();
    final remaining = until.difference(_now());
    final delay = remaining < const Duration(minutes: 1)
        ? remaining
        : const Duration(minutes: 1);
    _pauseTimer = Timer(delay, refreshAdPause);
  }

  void _rememberPause(DateTime? until) {
    final prefs = ref.read(sharedPrefsProvider);
    _pausePersistence = _pausePersistence.then((_) async {
      try {
        final saved = until == null
            ? await prefs.remove(_adPauseKey)
            : await prefs.setInt(_adPauseKey, until.millisecondsSinceEpoch);
        if (!saved) throw StateError('pause not saved');
      } catch (_) {
        if (!_disposed && until != null && state.adPauseUntil == until) {
          state = state.copyWith(
            rewardedMessage:
                'Jeda aktif di sesi ini. Pengaturannya belum dapat disimpan.',
          );
        }
      }
    });
  }

  void _suspendInterstitial() {
    final manager = _interstitialManager;
    _interstitialManager = null;
    unawaited(manager?.dispose());
  }

  void _handlePurchase(PurchaseUpdate update) {
    if (_disposed ||
        update.productId != MonetizationConfig.removeAdsProductId) {
      return;
    }
    switch (update.status) {
      case PurchaseUpdateStatus.purchased:
      case PurchaseUpdateStatus.restored:
        _waitingForPurchase = false;
        state = state.verified(price: update.price ?? state.productPrice);
        _suspendInterstitial();
        unawaited(_rewardedManager.dispose());
        unawaited(_rememberEntitlement());
      case PurchaseUpdateStatus.pending:
        _waitingForPurchase = true;
        state = state.copyWith(
          isVerifying: true,
          message:
              'Menunggu pembayaran selesai di Google Play. Jurnal tetap bisa dipakai.',
        );
      case PurchaseUpdateStatus.canceled:
        _waitingForPurchase = false;
        state = state.copyWith(
          isVerifying: false,
          message: 'Pembelian dibatalkan. Fitur jurnal tetap bisa dipakai.',
        );
      case PurchaseUpdateStatus.error:
        _waitingForPurchase = false;
        state = state.withMessage(
          update.errorMessage ?? 'Pembelian belum berhasil. Coba lagi.',
        );
    }
  }

  Future<void> _rememberEntitlement() async {
    try {
      await ref.read(sharedPrefsProvider).setBool(_entitlementHintKey, true);
    } catch (_) {
      // The Play entitlement remains valid; a later restoration can persist
      // the local hint again if storage was temporarily unavailable.
    }
  }

  String _friendlyError(Object error) {
    if (error is StateError) {
      final message = error.message.toString();
      return message.contains(MonetizationConfig.removeAdsProductId)
          ? _productUnavailableMessage
          : message;
    }
    return 'Google Play belum dapat menyelesaikan permintaan. Periksa koneksi lalu coba lagi.';
  }
}
