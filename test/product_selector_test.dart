import 'package:arunika_growth/domain/monetization/product_selector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class _PlatformProductDetails extends ProductDetails {
  _PlatformProductDetails(String id)
    : super(
        id: id,
        title: id,
        description: 'test',
        price: r'US$4.99',
        rawPrice: 4.99,
        currencyCode: 'USD',
      );
}

void main() {
  test('selects the requested product from a platform-specific list', () {
    final products = <_PlatformProductDetails>[
      _PlatformProductDetails('other_product'),
      _PlatformProductDetails('arunika_remove_ads'),
    ];

    final selected = selectProductDetails(products, 'arunika_remove_ads');

    expect(selected?.id, 'arunika_remove_ads');
  });

  test('exposes a Play Store query error to the purchase UI', () {
    final response = ProductDetailsResponse(
      productDetails: const <ProductDetails>[],
      notFoundIDs: const <String>[],
      error: IAPError(
        source: 'Google Play',
        code: 'SERVICE_UNAVAILABLE',
        message: 'Google Play sedang tidak tersedia',
      ),
    );

    expect(
      productQueryFailureMessage(response, 'arunika_remove_ads'),
      'Google Play sedang tidak tersedia',
    );
  });

  test('explains when the product is not available for this Play account', () {
    final response = ProductDetailsResponse(
      productDetails: const <ProductDetails>[],
      notFoundIDs: const <String>['arunika_remove_ads'],
    );

    expect(
      productQueryFailureMessage(response, 'arunika_remove_ads'),
      contains('belum tersedia'),
    );
  });
}
