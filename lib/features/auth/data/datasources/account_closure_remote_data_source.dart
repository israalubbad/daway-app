import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/networking/auth_options.dart';

class AccountClosureRemoteDataSource {
  final Dio _dio;

  const AccountClosureRemoteDataSource(this._dio);

  /// The backend only closes the account when [confirmationWord] is sent
  /// back verbatim, so a stray request can never delete it.
  static const confirmationWord = 'DELETE';

  Future<Response<dynamic>> closePatientAccount({required String token, String? reason}) {
    return _dio.post(
      ApiConstants.accountClosure,
      data: {'confirm': confirmationWord, 'reason': ?reason},
      options: authOptions(token),
    );
  }

  Future<Response<dynamic>> getPharmacyClosureRequest({required String token}) {
    return _dio.get(ApiConstants.pharmacyClosureRequest, options: authOptions(token));
  }

  Future<Response<dynamic>> requestPharmacyClosure({required String token, String? reason}) {
    return _dio.post(
      ApiConstants.pharmacyClosureRequest,
      data: {'reason': ?reason},
      options: authOptions(token),
    );
  }
}
