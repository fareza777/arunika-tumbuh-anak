/// UI-facing state for the ads and billing controller.
class MonetizationState {
  const MonetizationState({
    required this.adsRemoved,
    required this.isVerifying,
    required this.storeAvailable,
    this.productPrice,
    this.message,
  });

  const MonetizationState.initial()
      : adsRemoved = false,
        isVerifying = true,
        storeAvailable = false,
        productPrice = null,
        message = null;

  final bool adsRemoved;
  final bool isVerifying;
  final bool storeAvailable;
  final String? productPrice;
  final String? message;

  MonetizationState verified({String? price}) {
    return MonetizationState(
      adsRemoved: true,
      isVerifying: false,
      storeAvailable: true,
      productPrice: price ?? productPrice,
    );
  }

  MonetizationState withMessage(String message) {
    return MonetizationState(
      adsRemoved: adsRemoved,
      isVerifying: false,
      storeAvailable: storeAvailable,
      productPrice: productPrice,
      message: message,
    );
  }

  MonetizationState copyWith({
    bool? adsRemoved,
    bool? isVerifying,
    bool? storeAvailable,
    String? productPrice,
    String? message,
    bool clearMessage = false,
  }) {
    return MonetizationState(
      adsRemoved: adsRemoved ?? this.adsRemoved,
      isVerifying: isVerifying ?? this.isVerifying,
      storeAvailable: storeAvailable ?? this.storeAvailable,
      productPrice: productPrice ?? this.productPrice,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}
