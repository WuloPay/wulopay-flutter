import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wulopay_checkout/wulopay_checkout.dart';

const page = 'https://pay-sandbox.wulopay.com/c/cs_7CRIaOqGBtDY1J7ARiDLS7';

void main() {
  test('opens the sheet with the callback scheme and reads the result', () async {
    String? seenUrl, seenScheme;
    final result = await WuloPayCheckout.open(
      url: page,
      callbackScheme: 'myshop',
      authenticate: ({required url, required callbackUrlScheme}) async {
        seenUrl = url;
        seenScheme = callbackUrlScheme;
        return 'myshop://checkout?session_id=cs_7CRIaOqGBtDY1J7ARiDLS7&status=paid';
      },
    );
    expect(result, const CheckoutResult(CheckoutStatus.paid, 'cs_7CRIaOqGBtDY1J7ARiDLS7'));
    expect(seenUrl, page);
    expect(seenScheme, 'myshop');
  });

  test('reports a closed sheet as dismissed', () async {
    final result = await WuloPayCheckout.open(
      url: page,
      callbackScheme: 'myshop',
      authenticate: ({required url, required callbackUrlScheme}) async => throw PlatformException(code: 'CANCELED'),
    );
    expect(result.status, CheckoutStatus.dismissed);
  });

  test('refuses anything but a WuloPay payment page', () {
    for (final bad in ['http://pay.wulopay.com/c/cs_1', 'https://pay.wulopay.com.evil.example/c/cs_1', 'not a url']) {
      expect(
        () => WuloPayCheckout.open(
            url: bad, callbackScheme: 'myshop', authenticate: ({required url, required callbackUrlScheme}) async => ''),
        throwsArgumentError,
      );
    }
    expect(
      () => WuloPayCheckout.open(
          url: page, callbackScheme: 'https', authenticate: ({required url, required callbackUrlScheme}) async => ''),
      throwsArgumentError,
    );
  });

  test('treats unexpected values as unknown', () {
    expect(CheckoutResult.parse('myshop://checkout?session_id=%3Cscript%3E&status=hacked'),
        const CheckoutResult(CheckoutStatus.unknown, null));
  });
}
