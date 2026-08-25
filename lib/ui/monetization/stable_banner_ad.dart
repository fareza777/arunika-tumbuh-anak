import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/monetization/ad_retry_policy.dart';
import '../../domain/monetization/monetization_config.dart';
import '../../state/monetization_provider.dart';

enum BannerPlacement { mainShell }

/// The layout shell is intentionally independent from the ad plugin so its
/// height can be tested and kept stable while an ad is loading or retrying.
class StableBannerSlot extends StatelessWidget {
  static const defaultHeight = 54.0;

  const StableBannerSlot({
    super.key,
    required this.placement,
    required this.adsRemoved,
    this.height = defaultHeight,
    this.adWidget,
    this.hasError = false,
  });

  final BannerPlacement placement;
  final bool adsRemoved;
  final double height;
  final Widget? adWidget;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    if (adsRemoved) return const SizedBox.shrink();

    return SizedBox(
      key: ValueKey('banner-slot:${placement.name}'),
      width: double.infinity,
      height: height,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.pearl,
          border: Border(
            top: BorderSide(color: AppColors.hairline),
            bottom: BorderSide(color: AppColors.hairline),
          ),
        ),
        child: adWidget == null
            ? Center(
                child: Text(
                  hasError ? 'Iklan akan dimuat kembali' : 'Memuat iklan…',
                  style: AppTheme.sans(size: 10, color: AppColors.inkFaint),
                ),
              )
            : Center(child: adWidget),
      ),
    );
  }
}

/// One persistent adaptive banner used by the primary shell.
class StableBannerAd extends ConsumerStatefulWidget {
  const StableBannerAd({super.key, required this.placement});

  final BannerPlacement placement;

  @override
  ConsumerState<StableBannerAd> createState() => _StableBannerAdState();
}

class _StableBannerAdState extends ConsumerState<StableBannerAd> {
  final _config = MonetizationConfig.fromEnvironment();
  BannerAd? _ad;
  AdSize? _adSize;
  Timer? _retryTimer;
  var _failureCount = 0;
  var _loading = false;
  var _hasError = false;
  var _adLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(monetizationProvider);
    if (state.adsRemoved) {
      _disposeAd();
      return const SizedBox.shrink();
    }

    final ad = _ad;
    final adHeight = (_adSize?.height ?? StableBannerSlot.defaultHeight)
        .toDouble();
    return StableBannerSlot(
      placement: widget.placement,
      adsRemoved: false,
      height: adHeight < StableBannerSlot.defaultHeight
          ? StableBannerSlot.defaultHeight
          : adHeight,
      hasError: _hasError,
      adWidget: ad == null || !_adLoaded ? null : AdWidget(ad: ad),
    );
  }

  Future<void> _load() async {
    if (!mounted || _loading || _ad != null) return;
    if (ref.read(monetizationProvider).adsRemoved) return;

    final mobile =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    if (!mobile || (_config.isRelease && !_config.isValidForRelease)) {
      if (mounted) setState(() => _hasError = true);
      return;
    }

    _loading = true;
    if (mounted) setState(() => _hasError = false);

    try {
      // A standard 320x50 banner keeps the anchored slot compact and stable
      // across devices. The previous large adaptive format left a visibly
      // tall strip at the bottom of the family journal.
      const size = AdSize.banner;
      if (!mounted) return;

      final ad = BannerAd(
        size: size,
        adUnitId: _config.bannerAdUnitId,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (loaded) {
            if (!mounted) {
              loaded.dispose();
              return;
            }
            setState(() {
              _ad = loaded as BannerAd;
              _adSize = size;
              _adLoaded = true;
              _loading = false;
              _hasError = false;
              _failureCount = 0;
            });
          },
          onAdFailedToLoad: (failed, _) {
            failed.dispose();
            if (!mounted) return;
            setState(() {
              _loading = false;
              _hasError = true;
              _adLoaded = false;
              _failureCount++;
            });
            _scheduleRetry();
          },
        ),
      );
      _ad = ad;
      await ad.load();
    } catch (_) {
      if (!mounted) return;
      _ad?.dispose();
      _ad = null;
      _adLoaded = false;
      setState(() {
        _loading = false;
        _hasError = true;
        _failureCount++;
      });
      _scheduleRetry();
    }
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(AdRetryPolicy.nextDelay(_failureCount - 1), () {
      if (!mounted) return;
      _ad = null;
      unawaited(_load());
    });
  }

  void _disposeAd() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _ad?.dispose();
    _ad = null;
    _adSize = null;
    _adLoaded = false;
    _loading = false;
  }

  @override
  void dispose() {
    _disposeAd();
    super.dispose();
  }
}
