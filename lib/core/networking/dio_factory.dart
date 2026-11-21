import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/api_constants.dart';
import 'response_cache_interceptor.dart';
import 'response_cache_store.dart';
import 'session_expired_interceptor.dart';

abstract class DioFactory {
  static Dio getDio({
    void Function()? onSessionExpired,
    ResponseCacheStore? cacheStore,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        // Without `Accept: application/json` Laravel answers an unauthenticated
        // request with a 302 to the HTML /login page instead of a JSON 401.
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    if (onSessionExpired != null) {
      dio.interceptors.add(SessionExpiredInterceptor(onSessionExpired));
    }

    if (cacheStore != null) {
      dio.interceptors.add(ResponseCacheInterceptor(cacheStore));
    }

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }

    return dio;
  }
}
