import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../domain/monetization/ad_retry_policy.dart';
import '../../domain/monetization/ad_presentations.dart';
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
    final theme = Theme.of(context);

    return Semantics(
      label: hasError ? 'Iklan belum tersedia' : 'Iklan',
      container: true,
      child: SizedBox(
        key: ValueKey('banner-slot:${placement.name}'),
        width: double.infinity,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              top: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
          ),
          child: adWidget == null
              ? const SizedBox.expand()
              : Center(child: adWidget),
        ),
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
  var _generation = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(monetizationProvider);
    ref.listen(monetizationProvider, (previous, next) {
      if (previous?.adsSuppressed != next.adsSuppressed ||
          previous?.adConsentRevision != next.adConsentRevision) {
        _disposeAd();
        if (!next.adsSuppressed) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _load());
        }
      }
    });
    if (state.adsSuppressed) return const SizedBox.shrink();

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
    if (ref.read(monetizationProvider).adsSuppressed) return;

    final mobile =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    if (kIsWeb || !mobile || !_config.canUseBanner) {
      if (mounted) setState(() => _hasError = true);
      return;
    }

    _loading = true;
    final generation = ++_generation;
    if (mounted) setState(() => _hasError = false);

    try {
      if (!await canRequestMobileAds()) {
        _failLoad(generation);
        return;
      }
      // A standard 320x50 banner keeps the anchored slot compact and stable
      // across devices. The previous large adaptive format left a visibly
      // tall strip at the bottom of the family journal.
      const size = AdSize.banner;
      if (!_isCurrent(generation)) return;

      final ad = BannerAd(
        size: size,
        adUnitId: _config.bannerAdUnitId,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (loaded) {
            if (!_isCurrent(generation)) {
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
            if (!_isCurrent(generation)) return;
            setState(() {
              _ad = null;
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
      if (!_isCurrent(generation)) return;
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

  bool _isCurrent(int generation) =>
      mounted &&
      generation == _generation &&
      !ref.read(monetizationProvider).adsSuppressed;

  void _failLoad(int generation) {
    if (!_isCurrent(generation)) return;
    setState(() {
      _loading = false;
      _hasError = true;
      _failureCount++;
    });
    _scheduleRetry();
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(AdRetryPolicy.nextDelay(_failureCount - 1), () {
      if (!mounted || ref.read(monetizationProvider).adsSuppressed) return;
      _ad = null;
      unawaited(_load());
    });
  }

  void _disposeAd() {
    _generation++;
    _retryTimer?.cancel();
    _retryTimer = null;
    _ad?.dispose();
    _ad = null;
    _adSize = null;
    _adLoaded = false;
    _loading = false;
    _hasError = false;
  }

  @override
  void dispose() {
    _disposeAd();
    super.dispose();
  }
}
