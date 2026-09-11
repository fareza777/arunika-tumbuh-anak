import 'dart:async';

import 'package:arunika_growth/domain/monetization/ad_presentations.dart';
import 'package:arunika_growth/domain/monetization/monetization_config.dart';
import 'package:arunika_growth/domain/monetization/rewarded_ad_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

class _RewardedAd implements RewardedAdPresentation {
  VoidCallback? earned;
  VoidCallback? dismissed;
  VoidCallback? failed;
  int shows = 0;
  int disposals = 0;

  @override
  Future<void> show({
    required VoidCallback onEarned,
    required VoidCallback onDismissed,
    required VoidCallback onFailed,
  }) async {
    shows++;
    earned = onEarned;
    dismissed = onDismissed;
    failed = onFailed;
  }

  @override
  Future<void> dispose() async => disposals++;
}

void main() {
  late _RewardedAd ad;
  late RewardedAdManager manager;
  late int rewards;

  setUp(() {
    ad = _RewardedAd();
    rewards = 0;
    manager = RewardedAdManager(
      config: MonetizationConfig.fromEnvironment(
        isRelease: false,
        enableRewarded: true,
      ),
      isSupported: true,
      canRequestAds: () async => true,
      loadAd: (_) async => ad,
    );
  });
  tearDown(() => manager.dispose());

  Future<RewardedAdResult> watch({bool Function()? canPresent}) => manager.show(
    canPresent: canPresent ?? () => true,
    onEarned: () => rewards++,
  );

  test('only the earned callback grants one reward', () async {
    final result = watch();
    await pumpEventQueue();
    expect(ad.shows, 1);
    expect(rewards, 0);
    ad.earned!();
    ad.earned!();
    expect(rewards, 1);
    ad.dismissed!();
    expect(await result, RewardedAdResult.earned);
    expect(ad.disposals, 1);
  });

  test('dismissal without earning grants nothing', () async {
    final result = watch();
    await pumpEventQueue();
    ad.dismissed!();
    expect(await result, RewardedAdResult.dismissed);
    ad.earned!();
    expect(rewards, 0);
  });

  test('load failure and show failure grant nothing', () async {
    await manager.dispose();
    manager = RewardedAdManager(
      config: MonetizationConfig.fromEnvironment(
        isRelease: false,
        enableRewarded: true,
      ),
      isSupported: true,
      canRequestAds: () async => true,
      loadAd: (_) async => throw StateError('offline'),
    );
    expect(await watch(), RewardedAdResult.unavailable);
    expect(rewards, 0);

    await manager.dispose();
    manager = RewardedAdManager(
      config: MonetizationConfig.fromEnvironment(
        isRelease: false,
        enableRewarded: true,
      ),
      isSupported: true,
      canRequestAds: () async => true,
      loadAd: (_) async => ad,
    );
    final result = watch();
    await pumpEventQueue();
    ad.failed!();
    expect(await result, RewardedAdResult.unavailable);
    expect(rewards, 0);
  });

  test('leaving the route during loading disposes the late ad', () async {
    final loaded = Completer<RewardedAdPresentation>();
    var onScreen = true;
    await manager.dispose();
    manager = RewardedAdManager(
      config: MonetizationConfig.fromEnvironment(
        isRelease: false,
        enableRewarded: true,
      ),
      isSupported: true,
      canRequestAds: () async => true,
      loadAd: (_) => loaded.future,
    );
    final result = watch(canPresent: () => onScreen);
    await pumpEventQueue();
    onScreen = false;
    loaded.complete(ad);
    expect(await result, RewardedAdResult.canceled);
    expect(ad.shows, 0);
    expect(ad.disposals, 1);
    expect(rewards, 0);
  });

  test(
    'disposal while loading prevents late presentation and reward',
    () async {
      final loaded = Completer<RewardedAdPresentation>();
      await manager.dispose();
      manager = RewardedAdManager(
        config: MonetizationConfig.fromEnvironment(
          isRelease: false,
          enableRewarded: true,
        ),
        isSupported: true,
        canRequestAds: () async => true,
        loadAd: (_) => loaded.future,
      );
      final result = watch();
      await pumpEventQueue();
      await manager.dispose();
      loaded.complete(ad);
      expect(await result, RewardedAdResult.canceled);
      expect(ad.shows, 0);
      expect(ad.disposals, 1);
      expect(rewards, 0);
    },
  );

  test('the default disabled feature never loads a rewarded ad', () async {
    var requests = 0;
    await manager.dispose();
    manager = RewardedAdManager(
      config: MonetizationConfig.fromEnvironment(isRelease: false),
      isSupported: true,
      canRequestAds: () async => true,
      loadAd: (_) async {
        requests++;
        return ad;
      },
    );
    expect(manager.isEnabled, isFalse);
    expect(await watch(), RewardedAdResult.unavailable);
    expect(requests, 0);
    expect(rewards, 0);
  });

  test('missing release rewarded ID never requests or grants an ad', () async {
    var requests = 0;
    await manager.dispose();
    manager = RewardedAdManager(
      config: const MonetizationConfig(
        productId: MonetizationConfig.removeAdsProductId,
        admobAppId: 'ca-app-pub-1234567890123456~1234567890',
        bannerAdUnitId: 'ca-app-pub-1234567890123456/1234567890',
        interstitialAdUnitId: 'ca-app-pub-1234567890123456/1234567891',
        isRelease: true,
        enableRewarded: true,
      ),
      isSupported: true,
      canRequestAds: () async => true,
      loadAd: (_) async {
        requests++;
        return ad;
      },
    );
    expect(manager.isConfigured, isFalse);
    expect(await watch(), RewardedAdResult.unavailable);
    expect(requests, 0);
    expect(rewards, 0);
  });

  test('consent denial never requests an ad or grants a reward', () async {
    var requests = 0;
    await manager.dispose();
    manager = RewardedAdManager(
      config: MonetizationConfig.fromEnvironment(
        isRelease: false,
        enableRewarded: true,
      ),
      isSupported: true,
      canRequestAds: () async => false,
      loadAd: (_) async {
        requests++;
        return ad;
      },
    );
    expect(await watch(), RewardedAdResult.unavailable);
    expect(requests, 0);
    expect(rewards, 0);
  });
}
