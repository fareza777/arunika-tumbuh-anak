import 'package:arunika_growth/domain/monetization/monetization_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('debug uses test ads and the fixed product id', () {
    final config = MonetizationConfig.fromEnvironment(isRelease: false);

    expect(config.productId, 'arunika_remove_ads');
    expect(config.bannerAdUnitId, contains('3940256099942544'));
    expect(config.interstitialAdUnitId, contains('3940256099942544'));
    expect(config.rewardedAdUnitId, MonetizationConfig.testRewardedAdUnitId);
    expect(config.enableRewarded, isFalse);
    expect(config.canUseRewarded, isFalse);
    expect(config.isValidForRelease, isTrue);
  });

  test('release without real IDs is invalid', () {
    final config = MonetizationConfig(
      productId: 'arunika_remove_ads',
      admobAppId: '',
      bannerAdUnitId: '',
      interstitialAdUnitId: '',
      isRelease: true,
    );

    expect(config.isValidForRelease, isFalse);
    expect(config.enableRewarded, isFalse);
    expect(config.canUseRewarded, isFalse);
  });

  test('rewarded requires explicit opt in even when a real ID is present', () {
    const config = MonetizationConfig(
      productId: 'arunika_remove_ads',
      admobAppId: 'ca-app-pub-1234567890123456~1234567890',
      bannerAdUnitId: 'ca-app-pub-1234567890123456/1234567890',
      interstitialAdUnitId: 'ca-app-pub-1234567890123456/0987654321',
      rewardedAdUnitId: 'ca-app-pub-1234567890123456/1234567892',
      isRelease: true,
    );
    expect(config.canUseBanner, isTrue);
    expect(config.canUseInterstitial, isTrue);
    expect(config.canUseRewarded, isFalse);
  });

  test('release with real-looking IDs is valid', () {
    final config = MonetizationConfig(
      productId: 'arunika_remove_ads',
      admobAppId: 'ca-app-pub-1234567890123456~1234567890',
      bannerAdUnitId: 'ca-app-pub-1234567890123456/1234567890',
      interstitialAdUnitId: 'ca-app-pub-1234567890123456/0987654321',
      isRelease: true,
    );

    expect(config.isValidForRelease, isTrue);
  });
}
