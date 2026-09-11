/// UI-facing state for the ads and billing controller.
class MonetizationState {
  const MonetizationState({
    required this.adsRemoved,
    required this.isVerifying,
    required this.storeAvailable,
    this.productPrice,
    this.message,
    this.adPauseUntil,
    this.adPauseMinutesRemaining = 0,
    this.rewardedAvailable = false,
    this.isRewardedBusy = false,
    this.rewardedMessage,
    this.adConsentRevision = 0,
  });

  const MonetizationState.initial()
    : adsRemoved = false,
      isVerifying = true,
      storeAvailable = false,
      productPrice = null,
      message = null,
      adPauseUntil = null,
      adPauseMinutesRemaining = 0,
      rewardedAvailable = false,
      isRewardedBusy = false,
      rewardedMessage = null,
      adConsentRevision = 0;

  final bool adsRemoved;
  final bool isVerifying;
  final bool storeAvailable;
  final String? productPrice;
  final String? message;
  final DateTime? adPauseUntil;
  final int adPauseMinutesRemaining;
  final bool rewardedAvailable;
  final bool isRewardedBusy;
  final String? rewardedMessage;
  final int adConsentRevision;

  /// The controller expires a temporary pause on its timer and on resume.
  bool get adsSuppressed => adsRemoved || adPauseUntil != null;

  MonetizationState verified({String? price}) {
    return copyWith(
      adsRemoved: true,
      isVerifying: false,
      storeAvailable: true,
      productPrice: price ?? productPrice,
      clearMessage: true,
    );
  }

  MonetizationState withMessage(String message) {
    return copyWith(isVerifying: false, message: message);
  }

  MonetizationState copyWith({
    bool? adsRemoved,
    bool? isVerifying,
    bool? storeAvailable,
    String? productPrice,
    String? message,
    bool clearMessage = false,
    bool clearProductPrice = false,
    DateTime? adPauseUntil,
    bool clearAdPause = false,
    int? adPauseMinutesRemaining,
    bool? rewardedAvailable,
    bool? isRewardedBusy,
    String? rewardedMessage,
    bool clearRewardedMessage = false,
    int? adConsentRevision,
  }) {
    return MonetizationState(
      adsRemoved: adsRemoved ?? this.adsRemoved,
      isVerifying: isVerifying ?? this.isVerifying,
      storeAvailable: storeAvailable ?? this.storeAvailable,
      productPrice: clearProductPrice
          ? null
          : productPrice ?? this.productPrice,
      message: clearMessage ? null : message ?? this.message,
      adPauseUntil: clearAdPause ? null : adPauseUntil ?? this.adPauseUntil,
      adPauseMinutesRemaining: clearAdPause
          ? 0
          : adPauseMinutesRemaining ?? this.adPauseMinutesRemaining,
      rewardedAvailable: rewardedAvailable ?? this.rewardedAvailable,
      isRewardedBusy: isRewardedBusy ?? this.isRewardedBusy,
      rewardedMessage: clearRewardedMessage
          ? null
          : rewardedMessage ?? this.rewardedMessage,
      adConsentRevision: adConsentRevision ?? this.adConsentRevision,
    );
  }
}
