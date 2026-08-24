import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'interstitial_gate.dart';
import 'monetization_config.dart';

/// Loads one interstitial in advance and shows it only after a natural,
/// rate-limited completion point. The banner remains the primary ad surface.
class InterstitialAdManager {
  InterstitialAdManager({MonetizationConfig? config})
    : _config = config ?? MonetizationConfig.fromEnvironment();

  final MonetizationConfig _config;
  InterstitialAd? _ad;
  var _loading = false;
  var _disposed = false;

  Future<void> initialize() async {
    if (_disposed || !_supportsAds) return;
    try {
      if (!await ConsentInformation.instance.canRequestAds()) return;
    } catch (_) {
      return;
    }
    await preload();
  }

  Future<void> preload() async {
    if (_disposed || !_supportsAds || _loading || _ad != null) return;
    _loading = true;
    try {
      await InterstitialAd.load(
        adUnitId: _config.interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _loading = false;
            if (_disposed) {
              ad.dispose();
              return;
            }
            _ad = ad;
          },
          onAdFailedToLoad: (_) => _loading = false,
        ),
      );
    } catch (_) {
      _loading = false;
    }
  }

  Future<void> showIfEligible({
    required InterstitialGate gate,
    required bool adsRemoved,
  }) async {
    if (_disposed || adsRemoved || !gate.canShow(DateTime.now())) return;
    final ad = _ad;
    if (ad == null) {
      unawaited(preload());
      return;
    }

    _ad = null;
    gate.recordShown(DateTime.now());
    ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
      onAdDismissedFullScreenContent: (dismissed) {
        dismissed.dispose();
        unawaited(preload());
      },
      onAdFailedToShowFullScreenContent: (failed, _) {
        failed.dispose();
        unawaited(preload());
      },
    );
    try {
      await ad.show();
    } catch (error) {
      debugPrint('Arunika interstitial unavailable: $error');
      ad.dispose();
      unawaited(preload());
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    _ad?.dispose();
    _ad = null;
  }

  bool get _supportsAds {
    final mobile =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    return mobile && (!_config.isRelease || _config.isValidForRelease);
  }
}
