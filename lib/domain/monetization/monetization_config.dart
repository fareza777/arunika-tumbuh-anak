/// Runtime configuration for ads and Play Billing.
class MonetizationConfig {
  const MonetizationConfig({
    required this.productId,
    required this.admobAppId,
    required this.bannerAdUnitId,
    required this.interstitialAdUnitId,
    required this.isRelease,
  });

  static const removeAdsProductId = 'arunika_remove_ads';
  static const testAdmobAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const testInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';

  final String productId;
  final String admobAppId;
  final String bannerAdUnitId;
  final String interstitialAdUnitId;
  final bool isRelease;

  factory MonetizationConfig.fromEnvironment({bool? isRelease}) {
    final release = isRelease ?? const bool.fromEnvironment('dart.vm.product');
    if (!release) {
      return const MonetizationConfig(
        productId: removeAdsProductId,
        admobAppId: testAdmobAppId,
        bannerAdUnitId: testBannerAdUnitId,
        interstitialAdUnitId: testInterstitialAdUnitId,
        isRelease: false,
      );
    }

    return const MonetizationConfig(
      productId: removeAdsProductId,
      admobAppId: String.fromEnvironment('ADMOB_APP_ID'),
      bannerAdUnitId: String.fromEnvironment('ADMOB_BANNER_ID'),
      interstitialAdUnitId: String.fromEnvironment('ADMOB_INTERSTITIAL_ID'),
      isRelease: true,
    );
  }

  /// Release builds must be given real, non-test AdMob identifiers.
  bool get isValidForRelease {
    if (!isRelease) return true;
    return admobAppId.isNotEmpty &&
        bannerAdUnitId.isNotEmpty &&
        interstitialAdUnitId.isNotEmpty &&
        admobAppId != testAdmobAppId &&
        bannerAdUnitId != testBannerAdUnitId &&
        interstitialAdUnitId != testInterstitialAdUnitId;
  }
}
