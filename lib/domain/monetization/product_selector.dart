import 'package:in_app_purchase/in_app_purchase.dart';

/// Selects the requested product without using `firstWhere(orElse: ...)`.
///
/// Google Play returns a list backed by its concrete product subtype. A
/// `firstWhere` fallback typed as the base [ProductDetails] can fail at
/// runtime against that covariant list, so a simple loop keeps the boundary
/// safe on Android and iOS.
ProductDetails? selectProductDetails(
  Iterable<ProductDetails> products,
  String productId,
) {
  for (final product in products) {
    if (product.id == productId) return product;
  }
  return null;
}

/// Converts the two ways a storefront can reject a product query into a
/// message the billing UI can display without swallowing the cause.
String? productQueryFailureMessage(
  ProductDetailsResponse response,
  String productId,
) {
  final errorMessage = response.error?.message.trim();
  if (errorMessage != null && errorMessage.isNotEmpty) return errorMessage;
  if (response.notFoundIDs.contains(productId)) {
    return 'Produk Bebas Iklan belum tersedia untuk akun Google Play ini.';
  }
  return null;
}
