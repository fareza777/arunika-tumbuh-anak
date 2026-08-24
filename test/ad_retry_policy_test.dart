import 'package:arunika_growth/domain/monetization/ad_retry_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('banner retries use bounded 15/30/60 second delays', () {
    expect(AdRetryPolicy.nextDelay(0), const Duration(seconds: 15));
    expect(AdRetryPolicy.nextDelay(1), const Duration(seconds: 30));
    expect(AdRetryPolicy.nextDelay(2), const Duration(seconds: 60));
  });

  test('repeated banner failures cap at five minutes', () {
    expect(AdRetryPolicy.nextDelay(3), const Duration(minutes: 5));
    expect(AdRetryPolicy.nextDelay(4), const Duration(minutes: 5));
    expect(AdRetryPolicy.nextDelay(5), const Duration(minutes: 5));
    expect(AdRetryPolicy.nextDelay(99), const Duration(minutes: 5));
  });
}
