import 'dart:async';

import 'package:arunika_growth/domain/monetization/ad_presentations.dart';
import 'package:arunika_growth/domain/monetization/interstitial_ad_manager.dart';
import 'package:arunika_growth/domain/monetization/interstitial_gate.dart';
import 'package:arunika_growth/domain/monetization/monetization_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

class _InterstitialAd implements InterstitialAdPresentation {
  int shows = 0;
  int disposals = 0;
  VoidCallback? dismissed;
  bool failShow = false;

  @override
  Future<void> show({
    required VoidCallback onShown,
    required VoidCallback onDismissed,
    required VoidCallback onFailed,
  }) async {
    shows++;
    dismissed = onDismissed;
    if (failShow) {
      onFailed();
    } else {
      onShown();
    }
  }

  @override
  Future<void> dispose() async => disposals++;
}

void main() {
  late _InterstitialAd ad;
  late InterstitialAdManager manager;
  late InterstitialGate gate;
  late DateTime now;

  setUp(() {
    ad = _InterstitialAd();
    gate = InterstitialGate();
    now = DateTime(2026, 9, 5, 12);
    manager = InterstitialAdManager(
      config: MonetizationConfig.fromEnvironment(isRelease: false),
      isSupported: true,
      canRequestAds: () async => true,
      loadAd: (_) async => ad,
      now: () => now,
    );
  });
  tearDown(() => manager.dispose());

  Future<bool> completeSave({bool suppressed = false, bool onScreen = true}) {
    gate.recordMeaningfulSave();
    return manager.showIfEligible(
      gate: gate,
      adsRemoved: suppressed,
      canPresent: () => onScreen,
      adsSuppressed: () => suppressed,
    );
  }

  test('only the third completed save presents a cached ad', () async {
    expect(await completeSave(), isFalse);
    await pumpEventQueue();
    expect(await completeSave(), isFalse);
    expect(ad.shows, 0);
    expect(await completeSave(), isTrue);
    expect(ad.shows, 1);
    expect(gate.canShow(now), isFalse);
    ad.dismissed!();

    now = now.add(const Duration(minutes: 9));
    await completeSave();
    await pumpEventQueue();
    await completeSave();
    expect(await completeSave(), isFalse);
    expect(ad.shows, 1);
    now = now.add(const Duration(minutes: 1));
    expect(await completeSave(), isTrue);
    expect(ad.shows, 2);
    ad.dismissed!();
  });

  test('purchase or pause suppresses requests and presentation', () async {
    for (var count = 0; count < 4; count++) {
      expect(await completeSave(suppressed: true), isFalse);
    }
    await pumpEventQueue();
    expect(ad.shows, 0);
    expect(manager.hasCachedAd, isFalse);
  });

  test('leaving the completion route never presents a cached ad', () async {
    await manager.initialize();
    gate.recordMeaningfulSave();
    gate.recordMeaningfulSave();
    expect(await completeSave(onScreen: false), isFalse);
    expect(ad.shows, 0);
  });

  test(
    'loading completion never automatically opens an interstitial',
    () async {
      final loaded = Completer<InterstitialAdPresentation>();
      await manager.dispose();
      manager = InterstitialAdManager(
        config: MonetizationConfig.fromEnvironment(isRelease: false),
        isSupported: true,
        canRequestAds: () async => true,
        loadAd: (_) => loaded.future,
        now: () => now,
      );
      for (var count = 0; count < 3; count++) {
        expect(await completeSave(), isFalse);
      }
      loaded.complete(ad);
      await pumpEventQueue();
      expect(ad.shows, 0);
      expect(manager.hasCachedAd, isTrue);
    },
  );

  test(
    'a purchase or route change during consent check blocks presentation',
    () async {
      final consent = Completer<bool>();
      var checks = 0;
      var suppressed = false;
      var onScreen = true;
      await manager.dispose();
      manager = InterstitialAdManager(
        config: MonetizationConfig.fromEnvironment(isRelease: false),
        isSupported: true,
        canRequestAds: () async => ++checks == 1 ? true : consent.future,
        loadAd: (_) async => ad,
        now: () => now,
      );
      await manager.initialize();
      for (var i = 0; i < 3; i++) {
        gate.recordMeaningfulSave();
      }
      final showing = manager.showIfEligible(
        gate: gate,
        adsRemoved: false,
        canPresent: () => onScreen,
        adsSuppressed: () => suppressed,
      );
      await pumpEventQueue();
      suppressed = true;
      onScreen = false;
      consent.complete(true);
      expect(await showing, isFalse);
      expect(ad.shows, 0);
    },
  );

  test(
    'failed presentation does not consume the frequency allowance',
    () async {
      ad.failShow = true;
      await manager.initialize();
      gate.recordMeaningfulSave();
      gate.recordMeaningfulSave();
      await completeSave();
      expect(gate.canShow(now), isTrue);
    },
  );
}
