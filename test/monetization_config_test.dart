import 'package:arunika_growth/domain/monetization/monetization_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('debug uses test ads and the fixed product id', () {
    final config = MonetizationConfig.fromEnvironment(isRelease: false);

    expect(config.productId, 'arunika_remove_ads');
    expect(config.bannerAdUnitId, contains('3940256099942544'));
    expect(config.interstitialAdUnitId, contains('3940256099942544'));
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
