enum PurchaseUpdateStatus { pending, purchased, restored, canceled, error }

class MonetizationProduct {
  const MonetizationProduct({required this.id, required this.price});

  final String id;
  final String price;
}

class PurchaseUpdate {
  const PurchaseUpdate({
    required this.productId,
    required this.status,
    this.price,
    this.errorMessage,
  });

  final String productId;
  final PurchaseUpdateStatus status;
  final String? price;
  final String? errorMessage;
}

abstract interface class MonetizationGateway {
  Stream<PurchaseUpdate> get purchaseUpdates;

  Future<void> initialize();

  Future<bool> isAvailable();

  Future<MonetizationProduct?> queryRemoveAds();

  Future<void> restorePurchases();

  Future<void> buyRemoveAds();

  Future<void> dispose();
}
