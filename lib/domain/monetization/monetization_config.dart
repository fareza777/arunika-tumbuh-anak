/// Runtime configuration for ads and Play Billing.
class MonetizationConfig {
  const MonetizationConfig({
    required this.productId,
    required this.admobAppId,
    required this.bannerAdUnitId,
    required this.interstitialAdUnitId,
    required this.isRelease,
    this.rewardedAdUnitId = '',
    this.enableRewarded = false,
  });

  static const removeAdsProductId = 'arunika_remove_ads';
  static const testAdmobAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const testInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';

  final String productId;
  final String admobAppId;
  final String bannerAdUnitId;
  final String interstitialAdUnitId;
  final String rewardedAdUnitId;
  final bool enableRewarded;
  final bool isRelease;

  factory MonetizationConfig.fromEnvironment({
    bool? isRelease,
    bool? enableRewarded,
  }) {
    final release = isRelease ?? const bool.fromEnvironment('dart.vm.product');
    final rewardsEnabled =
        enableRewarded ??
        const bool.fromEnvironment('ENABLE_REWARDED', defaultValue: false);
    if (!release) {
      return MonetizationConfig(
        productId: removeAdsProductId,
        admobAppId: testAdmobAppId,
        bannerAdUnitId: testBannerAdUnitId,
        interstitialAdUnitId: testInterstitialAdUnitId,
        rewardedAdUnitId: testRewardedAdUnitId,
        enableRewarded: rewardsEnabled,
        isRelease: false,
      );
    }

    return MonetizationConfig(
      productId: removeAdsProductId,
      admobAppId: const String.fromEnvironment('ADMOB_APP_ID'),
      bannerAdUnitId: const String.fromEnvironment('ADMOB_BANNER_ID'),
      interstitialAdUnitId: const String.fromEnvironment(
        'ADMOB_INTERSTITIAL_ID',
      ),
      rewardedAdUnitId: const String.fromEnvironment('ADMOB_REWARDED_ID'),
      enableRewarded: rewardsEnabled,
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

  bool get canUseBanner => _hasAppId && _hasUnitId(bannerAdUnitId);
  bool get canUseInterstitial => _hasAppId && _hasUnitId(interstitialAdUnitId);
  bool get canUseRewarded =>
      enableRewarded && _hasAppId && _hasUnitId(rewardedAdUnitId);
  bool get hasAnyAdConfiguration =>
      canUseBanner || canUseInterstitial || canUseRewarded;

  bool get _hasAppId =>
      admobAppId.trim().isNotEmpty &&
      (!isRelease || !admobAppId.contains('3940256099942544'));

  bool _hasUnitId(String id) =>
      id.trim().isNotEmpty && (!isRelease || !id.contains('3940256099942544'));
}
