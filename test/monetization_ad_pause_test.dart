import 'dart:async';

import 'package:arunika_growth/core/theme/app_theme.dart';
import 'package:arunika_growth/domain/monetization/ad_presentations.dart';
import 'package:arunika_growth/domain/monetization/interstitial_ad_manager.dart';
import 'package:arunika_growth/domain/monetization/monetization_config.dart';
import 'package:arunika_growth/domain/monetization/monetization_gateway.dart';
import 'package:arunika_growth/domain/monetization/rewarded_ad_manager.dart';
import 'package:arunika_growth/state/app_settings.dart';
import 'package:arunika_growth/state/monetization_provider.dart';
import 'package:arunika_growth/ui/monetization/rewarded_break_card.dart';
import 'package:arunika_growth/ui/monetization/stable_banner_ad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Gateway implements MonetizationGateway {
  final updates = StreamController<PurchaseUpdate>.broadcast();
  Object? privacyError;
  @override
  Stream<PurchaseUpdate> get purchaseUpdates => updates.stream;
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
  Future<void> showPrivacyOptions() async {
    if (privacyError != null) throw privacyError!;
  }

  @override
  Future<void> dispose() => updates.close();
}

class _RewardedAd implements RewardedAdPresentation {
  VoidCallback? earn;
  VoidCallback? close;
  @override
  Future<void> show({
    required VoidCallback onEarned,
    required VoidCallback onDismissed,
    required VoidCallback onFailed,
  }) async {
    earn = onEarned;
    close = onDismissed;
  }

  @override
  Future<void> dispose() async {}
}

class _InterstitialAd implements InterstitialAdPresentation {
  int shows = 0;
  int disposals = 0;
  @override
  Future<void> show({
    required VoidCallback onShown,
    required VoidCallback onDismissed,
    required VoidCallback onFailed,
  }) async {
    shows++;
    onShown();
    onDismissed();
  }

  @override
  Future<void> dispose() async => disposals++;
}

class _FailingPreferences implements SharedPreferences {
  _FailingPreferences(this.delegate);
  final SharedPreferences delegate;
  @override
  bool? getBool(String key) => delegate.getBool(key);
  @override
  int? getInt(String key) => delegate.getInt(key);
  @override
  Future<bool> setInt(String key, int value) async => false;
  @override
  Future<bool> remove(String key) => delegate.remove(key);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pauseKey = 'rewarded_ad_pause_until';
  late SharedPreferences prefs;
  late ProviderContainer container;
  late _Gateway gateway;
  late _RewardedAd rewarded;
  late _InterstitialAd interstitial;
  late DateTime now;
  var rewardedLoads = 0;
  var interstitialLoads = 0;

  Future<void> open({
    Map<String, Object> saved = const {},
    bool failPersistence = false,
    bool rewardConfigured = true,
    bool rewardEnabled = true,
  }) async {
    SharedPreferences.setMockInitialValues(saved);
    prefs = await SharedPreferences.getInstance();
    gateway = _Gateway();
    rewarded = _RewardedAd();
    interstitial = _InterstitialAd();
    final config = rewardConfigured
        ? MonetizationConfig.fromEnvironment(
            isRelease: false,
            enableRewarded: rewardEnabled,
          )
        : const MonetizationConfig(
            productId: MonetizationConfig.removeAdsProductId,
            admobAppId: '',
            bannerAdUnitId: '',
            interstitialAdUnitId: '',
            isRelease: true,
            enableRewarded: true,
          );
    container = ProviderContainer(
      overrides: [
        sharedPrefsProvider.overrideWithValue(
          failPersistence ? _FailingPreferences(prefs) : prefs,
        ),
        monetizationGatewayProvider.overrideWithValue(gateway),
        monetizationClockProvider.overrideWithValue(() => now),
        rewardedAdManagerProvider.overrideWithValue(
          RewardedAdManager(
            config: config,
            isSupported: true,
            canRequestAds: () async => true,
            loadAd: (_) async {
              rewardedLoads++;
              return rewarded;
            },
          ),
        ),
        interstitialAdManagerFactoryProvider.overrideWithValue(
          () => InterstitialAdManager(
            config: MonetizationConfig.fromEnvironment(
              isRelease: false,
              enableRewarded: true,
            ),
            isSupported: true,
            canRequestAds: () async => true,
            now: () => now,
            loadAd: (_) async {
              interstitialLoads++;
              return interstitial;
            },
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
  }

  setUp(() {
    now = DateTime(2026, 9, 5, 12);
    rewardedLoads = 0;
    interstitialLoads = 0;
  });

  MonetizationController controller() =>
      container.read(monetizationProvider.notifier);

  Future<void> earnBreak() async {
    final watching = controller().watchRewardedBreak(canPresent: () => true);
    await pumpEventQueue();
    rewarded.earn!();
    rewarded.close!();
    await watching;
    await pumpEventQueue();
  }

  test('startup never requests an interstitial or a rewarded ad', () async {
    await open();
    container.read(monetizationProvider);
    await pumpEventQueue();
    expect(interstitialLoads, 0);
    expect(rewardedLoads, 0);
  });

  test(
    'earned callback immediately pauses ads and persists the exact expiry',
    () async {
      await open();
      final watching = controller().watchRewardedBreak(canPresent: () => true);
      await pumpEventQueue();
      expect(container.read(monetizationProvider).adsSuppressed, isFalse);
      rewarded.earn!();
      expect(container.read(monetizationProvider).adsSuppressed, isTrue);
      expect(container.read(monetizationProvider).adsRemoved, isFalse);
      expect(container.read(monetizationProvider).adPauseMinutesRemaining, 30);
      rewarded.close!();
      await watching;
      await pumpEventQueue();
      expect(
        prefs.getInt(pauseKey),
        now.add(const Duration(minutes: 30)).millisecondsSinceEpoch,
      );
    },
  );

  test(
    'closing without earning neither pauses nor persists an entitlement',
    () async {
      await open();
      final watching = controller().watchRewardedBreak(canPresent: () => true);
      await pumpEventQueue();
      rewarded.close!();
      await watching;
      expect(container.read(monetizationProvider).adsSuppressed, isFalse);
      expect(prefs.getInt(pauseKey), isNull);
      expect(
        container.read(monetizationProvider).rewardedMessage,
        contains('belum diaktifkan'),
      );
    },
  );

  test('restored pause survives a store error and expires on resume', () async {
    final until = now.add(const Duration(minutes: 17));
    await open(saved: {pauseKey: until.millisecondsSinceEpoch});
    expect(container.read(monetizationProvider).adsSuppressed, isTrue);
    await pumpEventQueue();
    expect(container.read(monetizationProvider).storeAvailable, isFalse);
    expect(container.read(monetizationProvider).adPauseUntil, until);
    now = until;
    controller().refreshAdPause();
    await pumpEventQueue();
    expect(container.read(monetizationProvider).adsSuppressed, isFalse);
    expect(prefs.getInt(pauseKey), isNull);
  });

  test(
    'expired and invalid future saved pauses do not grant a new break',
    () async {
      for (final until in [
        now,
        now.subtract(const Duration(days: 1)),
        now.add(const Duration(days: 1)),
      ]) {
        await open(saved: {pauseKey: until.millisecondsSinceEpoch});
        expect(container.read(monetizationProvider).adsSuppressed, isFalse);
        container.dispose();
      }
    },
  );

  test(
    'reward pause blocks all further ad requests and evicts a cached interstitial',
    () async {
      await open();
      await controller().onMomentSavedAndReturned(canPresent: () => true);
      await pumpEventQueue();
      expect(interstitialLoads, 1);
      await earnBreak();
      expect(interstitial.disposals, 1);
      for (var i = 0; i < 4; i++) {
        expect(
          await controller().onMomentSavedAndReturned(canPresent: () => true),
          isFalse,
        );
      }
      await controller().watchRewardedBreak(canPresent: () => true);
      expect(rewardedLoads, 1);
      expect(interstitialLoads, 1);
      expect(interstitial.shows, 0);
    },
  );

  test(
    'a restored purchase suppresses optional and automatic ad placements',
    () async {
      await open();
      container.read(monetizationProvider);
      gateway.updates.add(
        const PurchaseUpdate(
          productId: MonetizationConfig.removeAdsProductId,
          status: PurchaseUpdateStatus.restored,
        ),
      );
      await pumpEventQueue();
      expect(container.read(monetizationProvider).adsSuppressed, isTrue);
      await controller().watchRewardedBreak(canPresent: () => true);
      for (var i = 0; i < 4; i++) {
        await controller().onMomentSavedAndReturned(canPresent: () => true);
      }
      expect(rewardedLoads, 0);
      expect(interstitialLoads, 0);
    },
  );

  test('persistence failure warning survives earned-ad dismissal', () async {
    await open(failPersistence: true);
    final watching = controller().watchRewardedBreak(canPresent: () => true);
    await pumpEventQueue();
    rewarded.earn!();
    await pumpEventQueue();
    expect(
      container.read(monetizationProvider).rewardedMessage,
      contains('sesi ini'),
    );
    rewarded.close!();
    await watching;
    expect(container.read(monetizationProvider).adsSuppressed, isTrue);
    expect(
      container.read(monetizationProvider).rewardedMessage,
      contains('sesi ini'),
    );
  });

  test('privacy failure reaches the settings error handler', () async {
    await open(saved: {'ads_removed_hint': true});
    gateway.privacyError = StateError('Opsi privasi belum tersedia');
    container.read(monetizationProvider);
    await expectLater(controller().showPrivacyOptions(), throwsStateError);
    expect(container.read(monetizationProvider).adsRemoved, isTrue);
  });

  for (final brightness in Brightness.values) {
    testWidgets('reward card wraps at 320px and 2x text in $brightness', (
      tester,
    ) async {
      await open();
      tester.view.physicalSize = const Size(320, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.build(brightness: brightness),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: const Scaffold(
              body: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: RewardedBreakCard(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final button = find.widgetWithText(
        FilledButton,
        'Tonton untuk jeda 30 menit',
      );
      expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull);
      expect(find.textContaining('Semua fitur tetap gratis'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('disabled rewarded feature displays no offer', (tester) async {
    await open(rewardEnabled: false);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: RewardedBreakCard())),
      ),
    );
    await tester.pump();
    expect(find.byType(FilledButton), findsNothing);
    expect(find.textContaining('Jeda iklan'), findsNothing);
    expect(rewardedLoads, 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'unconfigured release offer is visibly unavailable and disabled',
    (tester) async {
      await open(rewardConfigured: false);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: RewardedBreakCard())),
        ),
      );
      await tester.pump();
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
      expect(find.text('Iklan belum tersedia'), findsOneWidget);
      expect(rewardedLoads, 0);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'banner resumes and countdown updates when a pause timer expires',
    (tester) async {
      final until = now.add(const Duration(minutes: 2));
      await open(saved: {pauseKey: until.millisecondsSinceEpoch});
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    StableBannerAd(placement: BannerPlacement.mainShell),
                    RewardedBreakCard(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final banner = find.byKey(const ValueKey('banner-slot:mainShell'));
      expect(banner, findsNothing);
      expect(find.textContaining('Sisa sekitar 2 menit'), findsOneWidget);
      now = now.add(const Duration(minutes: 1));
      await tester.pump(const Duration(minutes: 1));
      expect(find.textContaining('Sisa sekitar 1 menit'), findsOneWidget);
      now = until;
      await tester.pump(const Duration(minutes: 1));
      await tester.pump();
      expect(container.read(monetizationProvider).adsSuppressed, isFalse);
      expect(banner, findsOneWidget);
      expect(find.text('Jeda iklan aktif'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      // Finish a native consent request that was in flight when the banner was
      // disposed; its late completion must not update a disposed widget.
      await tester.pump(const Duration(seconds: 8));
    },
  );

  testWidgets('purchase hides the actual banner and rewarded offer', (
    tester,
  ) async {
    await open(saved: {'ads_removed_hint': true});
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                StableBannerAd(placement: BannerPlacement.mainShell),
                RewardedBreakCard(),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('banner-slot:mainShell')), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
