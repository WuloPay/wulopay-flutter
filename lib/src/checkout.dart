import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

/// What the payment page reported when it sent the shopper back to the app.
enum CheckoutStatus {
  /// The page reported the payment as paid.
  paid,

  /// The shopper cancelled on the payment page.
  cancelled,

  /// The payment link had expired.
  expired,

  /// The shopper closed the browser sheet.
  dismissed,

  /// Anything else.
  unknown,
}

/// The result of [WuloPayCheckout.open]. Display only: ask **your backend** for the session's real status
/// (webhook or retrieve) before treating an order as paid.
class CheckoutResult {
  /// Creates a result.
  const CheckoutResult(this.status, this.sessionId);

  /// What the page reported.
  final CheckoutStatus status;

  /// The checkout session id (`cs_…`), when the page reported one.
  final String? sessionId;

  static final RegExp _sessionId = RegExp(r'^cs_[0-9A-Za-z]{10,40}$');

  /// Reads the app link WuloPay opened: your returnUrl or cancelUrl plus `?session_id=…&status=…`.
  static CheckoutResult parse(String link) {
    final uri = Uri.tryParse(link);
    final params = uri?.queryParameters ?? const <String, String>{};
    final status = switch (params['status']) {
      'paid' => CheckoutStatus.paid,
      'cancelled' => CheckoutStatus.cancelled,
      'expired' => CheckoutStatus.expired,
      _ => CheckoutStatus.unknown,
    };
    final id = params['session_id'];
    return CheckoutResult(status, id != null && _sessionId.hasMatch(id) ? id : null);
  }

  @override
  bool operator ==(Object other) => other is CheckoutResult && other.status == status && other.sessionId == sessionId;

  @override
  int get hashCode => Object.hash(status, sessionId);

  @override
  String toString() => 'CheckoutResult($status, $sessionId)';
}

/// Opens the browser sheet and returns the callback URL (the default uses flutter_web_auth_2).
typedef Authenticate = Future<String> Function({required String url, required String callbackUrlScheme});

/// WuloPay's payment page hosts. A session URL from anywhere else is refused unless you allow its host.
const Set<String> wuloPayPageHosts = {'pay.wulopay.com', 'pay-sandbox.wulopay.com'};

/// Opens WuloPay hosted checkout. Card details and 3-D Secure happen on WuloPay's secure page in a trusted
/// browser, never in a web view inside your app.
class WuloPayCheckout {
  WuloPayCheckout._();

  /// Opens the session [url] your backend got from WuloPay (never create sessions in the app) and waits for the
  /// payment page to open your app link, whose scheme is [callbackScheme] (e.g. `myshop` for `myshop://checkout`).
  ///
  /// Throws [ArgumentError] when [url] isn't an https WuloPay payment page (add hosts with [allowedHosts]).
  static Future<CheckoutResult> open({
    required String url,
    required String callbackScheme,
    Set<String> allowedHosts = const {},
    Authenticate? authenticate,
  }) async {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        uri.scheme != 'https' ||
        !{...wuloPayPageHosts, ...allowedHosts}.contains(uri.host.toLowerCase())) {
      throw ArgumentError.value(url, 'url', 'not a WuloPay payment page');
    }
    if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*$').hasMatch(callbackScheme) ||
        {'http', 'https'}.contains(callbackScheme.toLowerCase())) {
      throw ArgumentError.value(callbackScheme, 'callbackScheme', 'must be your app link scheme');
    }
    final run = authenticate ??
        ({required String url, required String callbackUrlScheme}) =>
            FlutterWebAuth2.authenticate(url: url, callbackUrlScheme: callbackUrlScheme);
    try {
      return CheckoutResult.parse(await run(url: url, callbackUrlScheme: callbackScheme));
    } on PlatformException catch (e) {
      if (e.code == 'CANCELED') return const CheckoutResult(CheckoutStatus.dismissed, null);
      rethrow;
    }
  }
}
