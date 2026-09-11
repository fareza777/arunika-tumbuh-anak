import 'dart:async';

import 'ad_presentations.dart';
import 'interstitial_gate.dart';
import 'monetization_config.dart';

/// Keeps one ad for a completed-save transition. A late load is cached only:
/// it can never appear after the user has already resumed browsing or editing.
class InterstitialAdManager {
  InterstitialAdManager({
    MonetizationConfig? config,
    bool? isSupported,
    Future<bool> Function()? canRequestAds,
    Future<InterstitialAdPresentation> Function(String)? loadAd,
    DateTime Function()? now,
  }) : _config = config ?? MonetizationConfig.fromEnvironment(),
       _isSupported = isSupported ?? supportsMobileAds,
       _canRequestAds = canRequestAds ?? canRequestMobileAds,
       _loadAd = loadAd ?? loadInterstitialAd,
       _now = now ?? DateTime.now;

  final MonetizationConfig _config;
  final bool _isSupported;
  final Future<bool> Function() _canRequestAds;
  final Future<InterstitialAdPresentation> Function(String) _loadAd;
  final DateTime Function() _now;
  InterstitialAdPresentation? _ad;
  var _loading = false;
  var _showing = false;
  var _disposed = false;

  bool get hasCachedAd => _ad != null;

  Future<void> initialize() => preload();

  Future<void> preload() async {
    if (_disposed ||
        !_isSupported ||
        !_config.canUseInterstitial ||
        _loading ||
        _showing ||
        _ad != null) {
      return;
    }
    _loading = true;
    try {
      if (!await _canRequestAds() || _disposed) return;
      final ad = await _loadAd(_config.interstitialAdUnitId);
      if (_disposed) {
        await ad.dispose();
        return;
      }
      _ad = ad;
    } catch (_) {
      // An unavailable ad never blocks a save or navigation.
    } finally {
      _loading = false;
    }
  }

  Future<bool> showIfEligible({
    required InterstitialGate gate,
    required bool adsRemoved,
    required bool Function() canPresent,
    required bool Function() adsSuppressed,
  }) async {
    bool eligibleRoute() =>
        !_disposed && !adsRemoved && !adsSuppressed() && canPresent();
    if (_showing || !eligibleRoute()) return false;
    if (_ad == null) {
      unawaited(preload());
      return false;
    }
    if (!gate.canShow(_now())) return false;
    if (!await _canRequestAds() || !eligibleRoute()) return false;

    final ad = _ad;
    if (ad == null || _showing) return false;
    _ad = null;
    _showing = true;
    var finished = false;
    var shown = false;
    void finish() {
      if (finished) return;
      finished = true;
      _showing = false;
      unawaited(ad.dispose());
    }

    try {
      await ad.show(
        onShown: () {
          if (shown || finished) return;
          shown = true;
          gate.recordShown(_now());
        },
        onDismissed: finish,
        onFailed: finish,
      );
      return !finished || shown;
    } catch (_) {
      finish();
      return false;
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    final ad = _ad;
    _ad = null;
    await ad?.dispose();
    // A presented native overlay disposes itself from its completion callback.
  }
}
