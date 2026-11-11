import 'dart:convert';

import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import 'response_cache_store.dart';

/// A route whose GET answers are kept. [freshFor] is how long the kept answer
/// is served without asking the server at all (zero: always ask, and use the
/// kept one only when there is no connection).
class CacheRule {
  final String path;
  final Duration freshFor;

  const CacheRule(this.path, {this.freshFor = Duration.zero});

  bool matches(String requestPath) => requestPath == path || requestPath.startsWith('$path/');
}

/// What is kept, and for how long it is trusted. Catalogue data, which changes
/// rarely, is served from the cache for a while; the rest (the user's own
/// lists and stock) is always fetched and only falls back to the kept copy when
/// the device is offline, so a change made a minute ago is never hidden.
const defaultCacheRules = <CacheRule>[
  CacheRule(ApiConstants.categories, freshFor: Duration(hours: 1)),
  CacheRule(ApiConstants.dosageForms, freshFor: Duration(hours: 1)),
  CacheRule(ApiConstants.medicines, freshFor: Duration(minutes: 2)),
  CacheRule(ApiConstants.pharmacies),
  CacheRule(ApiConstants.patientFavoriteMedicines),
  CacheRule(ApiConstants.patientOrders),
  CacheRule(ApiConstants.pharmacySubOrders),
];

/// Keeps the JSON answers of the GET requests in [rules] on the device:
/// serves a fresh copy without a request, and answers from the last copy when
/// the request fails for lack of a connection. Everything else — other routes,
/// other methods, error answers, answers over [maxBodyBytes] — passes through
/// untouched, so a screen cannot tell the difference except by being faster
/// (or by working offline).
///
/// Each answer is kept per signed-in user (the bearer token is part of its key)
/// so one account never sees another's data.
class ResponseCacheInterceptor extends Interceptor {
  /// An answer older than this is not used even offline.
  static const maxStale = Duration(days: 7);

  /// Marks a response that came from the cache (`response.extra[fromCacheKey]`).
  static const fromCacheKey = 'fromCache';

  final ResponseCacheStore _store;
  final List<CacheRule> _rules;
  final int maxBodyBytes;
  final DateTime Function() _now;

  ResponseCacheInterceptor(
    this._store, {
    List<CacheRule> rules = defaultCacheRules,
    this.maxBodyBytes = 256 * 1024,
    DateTime Function()? now,
  }) : _rules = rules,
       _now = now ?? DateTime.now;

  CacheRule? _ruleFor(RequestOptions options) {
    if (options.method != 'GET') return null;
    for (final rule in _rules) {
      if (rule.matches(options.path)) return rule;
    }
    return null;
  }

  String _key(RequestOptions options) =>
      '${options.uri}|${options.headers['Authorization'] ?? ''}';

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final rule = _ruleFor(options);
    if (rule == null || rule.freshFor == Duration.zero) return handler.next(options);

    final cached = await _store.read(_key(options));
    if (cached != null && _now().difference(cached.storedAt) < rule.freshFor) {
      return handler.resolve(_response(options, cached));
    }
    handler.next(options);
  }

  @override
  Future<void> onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) async {
    final options = response.requestOptions;
    if (_ruleFor(options) != null &&
        response.statusCode == 200 &&
        response.extra[fromCacheKey] != true) {
      await _keep(options, response.data);
    }
    handler.next(response);
  }

  Future<void> _keep(RequestOptions options, Object? body) async {
    if (body is! Map && body is! List) return;
    try {
      // Measured as it will be stored, so one huge list cannot fill the cache.
      if (utf8.encode(jsonEncode(body)).length > maxBodyBytes) return;
      await _store.write(_key(options), CachedResponse(body: body, storedAt: _now()));
    } catch (_) {
      // Not JSON-encodable: simply not kept.
    }
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    if (_ruleFor(options) == null || !_isOffline(err)) return handler.next(err);

    final cached = await _store.read(_key(options));
    if (cached != null && _now().difference(cached.storedAt) < maxStale) {
      return handler.resolve(_response(options, cached));
    }
    handler.next(err);
  }

  /// A failure with no answer from the server: no network, or it timed out.
  static bool _isOffline(DioException err) =>
      err.response == null &&
      (err.type == DioExceptionType.connectionError ||
          err.type == DioExceptionType.connectionTimeout ||
          err.type == DioExceptionType.sendTimeout ||
          err.type == DioExceptionType.receiveTimeout);

  Response<dynamic> _response(RequestOptions options, CachedResponse cached) => Response<dynamic>(
    requestOptions: options,
    statusCode: 200,
    data: cached.body,
    extra: {fromCacheKey: true},
  );
}
