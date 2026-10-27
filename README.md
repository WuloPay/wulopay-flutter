# wulopay_checkout

Open WuloPay hosted checkout from a Flutter app in the system browser sheet (ASWebAuthenticationSession on iOS,
Custom Tabs on Android) and get the result back through your app link. Card details and 3-D Secure happen on
WuloPay's secure payment page, in a trusted browser, never in a web view inside your app.

```
flutter pub add wulopay_checkout
```

## Use

1. **Your backend** creates the checkout session with its API key (never the app) and sets `returnUrl` and
   `cancelUrl` to your app link, e.g. `myshop://checkout`. It returns the session `url` to the app.
2. Open it:

```dart
import 'package:wulopay_checkout/wulopay_checkout.dart';

final result = await WuloPayCheckout.open(url: sessionUrl, callbackScheme: 'myshop');
if (result.status == CheckoutStatus.paid) {
  // show "Confirming your payment…" and ask your backend for the order status
}
```

`result.status` (`paid`, `cancelled`, `expired`, `dismissed`, `unknown`) is what the payment page reported, for
display. Mark orders paid on your server, from the `checkout.session.completed` webhook or by retrieving the session.

## Platform set-up

This package uses [flutter_web_auth_2](https://pub.dev/packages/flutter_web_auth_2). On **Android**, add its callback
activity for your scheme to `AndroidManifest.xml`:

```xml
<activity android:name="com.linusu.flutter_web_auth_2.CallbackActivity" android:exported="true">
  <intent-filter android:label="flutter_web_auth_2">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="myshop" />
  </intent-filter>
</activity>
```

iOS needs no set-up. For safety, `open` only accepts https URLs on WuloPay's payment hosts (add others with
`allowedHosts`).

API and webhooks: [wulopay-openapi](https://github.com/WuloPay/wulopay-openapi). Sandbox keys: api@wulopay.com.
MIT licensed. Security problems: see [SECURITY.md](SECURITY.md).
