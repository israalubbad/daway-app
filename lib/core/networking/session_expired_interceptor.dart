import 'package:dio/dio.dart';

/// Put in a request's `extra` (value `true`) when a 401 on it is expected and
/// must not be reported as an expired session — the requests made while the
/// session is being ended on purpose (logout, removing the device's push token),
/// whose token the server has already revoked.
const skipSessionExpiryKey = 'skipSessionExpiry';

/// Reports a 401 on a request that carried a bearer token — i.e. the stored
/// session is no longer valid. A 401 without a token (wrong credentials at
/// login) is not a session expiry and is ignored, nor is one on a request
/// marked with [skipSessionExpiryKey]. The error still propagates, so the
/// screen that made the call keeps its own error handling.
class SessionExpiredInterceptor extends Interceptor {
  final void Function() onSessionExpired;

  SessionExpiredInterceptor(this.onSessionExpired);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final request = err.requestOptions;
    final hadToken = request.headers.containsKey('Authorization');
    final skipped = request.extra[skipSessionExpiryKey] == true;
    if (err.response?.statusCode == 401 && hadToken && !skipped) {
      onSessionExpired();
    }
    handler.next(err);
  }
}
