import 'package:dio/dio.dart';

/// Reports a 401 on a request that carried a bearer token — i.e. the stored
/// session is no longer valid. A 401 without a token (wrong credentials at
/// login) is not a session expiry and is ignored. The error still propagates,
/// so the screen that made the call keeps its own error handling.
class SessionExpiredInterceptor extends Interceptor {
  final void Function() onSessionExpired;

  SessionExpiredInterceptor(this.onSessionExpired);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final hadToken = err.requestOptions.headers.containsKey('Authorization');
    if (err.response?.statusCode == 401 && hadToken) {
      onSessionExpired();
    }
    handler.next(err);
  }
}
