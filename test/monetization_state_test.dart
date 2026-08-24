import 'package:arunika_growth/domain/monetization/monetization_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('initial state keeps ads visible while purchase is verified', () {
    const state = MonetizationState.initial();

    expect(state.adsRemoved, isFalse);
    expect(state.isVerifying, isTrue);
    expect(state.storeAvailable, isFalse);
  });

  test('verified entitlement removes ads and stops verification', () {
    final state = const MonetizationState.initial().verified(price: 'US\$4.99');

    expect(state.adsRemoved, isTrue);
    expect(state.isVerifying, isFalse);
    expect(state.productPrice, 'US\$4.99');
  });

  test('verification error does not revoke a previously verified entitlement', () {
    final verified = const MonetizationState.initial().verified();
    final state = verified.withMessage('Play Store sementara tidak tersedia');

    expect(state.adsRemoved, isTrue);
    expect(state.isVerifying, isFalse);
    expect(state.message, 'Play Store sementara tidak tersedia');
  });

  test('unverified errors keep ads visible', () {
    final state = const MonetizationState.initial().withMessage('Gagal memuat produk');

    expect(state.adsRemoved, isFalse);
    expect(state.message, 'Gagal memuat produk');
  });
}
