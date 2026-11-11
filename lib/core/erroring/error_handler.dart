import 'package:dio/dio.dart';

import 'api_error_model.dart';
import 'failure.dart';

import '../../core/localization/translations.dart';
String get _genericErrorMessage => 'حدث خطأ ما، يرجى المحاولة لاحقاً'.tr;

Failure mapExceptionToFailure(Object error) {
  if (error is DioException) {
    return _mapDioException(error);
  }
  return UnknownFailure(_genericErrorMessage);
}

Failure _mapDioException(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return NetworkFailure('انتهت مهلة الاتصال، يرجى المحاولة مرة أخرى'.tr);
    case DioExceptionType.connectionError:
      return NetworkFailure('تعذر الاتصال بالخادم، تحقق من اتصالك بالإنترنت'.tr);
    case DioExceptionType.cancel:
      return UnknownFailure('تم إلغاء الطلب'.tr);
    case DioExceptionType.badResponse:
      return _mapBadResponse(error);
    default:
      return NetworkFailure('تعذر الاتصال بالخادم، تحقق من اتصالك بالإنترنت'.tr);
  }
}

Failure _mapBadResponse(DioException error) {
  final statusCode = error.response?.statusCode;
  final responseData = error.response?.data;

  final apiError = responseData is Map<String, dynamic>
      ? ApiErrorModel.fromJson(responseData)
      : null;

  final message = apiError?.message ??
      arabicMessageForErrorCode(apiError?.code, statusCode) ??
      _genericErrorMessage;

  return ApiFailure(
    message: message,
    code: apiError?.code,
    statusCode: statusCode,
    registrationRequired: apiError?.registrationRequired ?? false,
  );
}

/// Maps a backend error code (or, as a fallback, an HTTP status code) to a
/// user-friendly Arabic message. Returns null when neither is recognized,
/// so callers can fall back to the server-provided message or a generic one.
String? arabicMessageForErrorCode(String? code, int? statusCode) {
  switch (code) {
    case 'VALIDATION_ERROR':
      return 'يرجى التحقق من البيانات المدخلة'.tr;
    case 'UNAUTHORIZED':
      return 'انتهت الجلسة، يرجى تسجيل الدخول مرة أخرى'.tr;
    case 'FORBIDDEN':
      return 'ليس لديك صلاحية للقيام بهذا الإجراء'.tr;
    case 'PHONE_EXISTS':
      return 'رقم الجوال مسجل مسبقاً'.tr;
    case 'INVALID_CREDENTIALS':
      return 'بيانات الدخول غير صحيحة'.tr;
    case 'OTP_INVALID':
      return 'رمز التحقق غير صحيح'.tr;
    case 'OTP_EXPIRED':
      return 'انتهت صلاحية رمز التحقق، يرجى طلب رمز جديد'.tr;
    case 'TOKEN_EXPIRED':
      return 'انتهت صلاحية الجلسة، يرجى تسجيل الدخول مرة أخرى'.tr;
    case 'ACCOUNT_INACTIVE':
      return 'حسابك غير مفعّل، يرجى التواصل مع الدعم'.tr;
  }

  switch (statusCode) {
    case 400:
    case 422:
      return 'يرجى التحقق من البيانات المدخلة'.tr;
    case 401:
      return 'انتهت الجلسة، يرجى تسجيل الدخول مرة أخرى'.tr;
    case 403:
      return 'ليس لديك صلاحية للقيام بهذا الإجراء'.tr;
    case 404:
      return 'الخدمة المطلوبة غير متوفرة'.tr;
    case 429:
      return 'محاولات كثيرة، يرجى المحاولة لاحقاً'.tr;
    case 500:
    case 502:
    case 503:
      return 'حدث خطأ في الخادم، يرجى المحاولة لاحقاً'.tr;
  }

  return null;
}
