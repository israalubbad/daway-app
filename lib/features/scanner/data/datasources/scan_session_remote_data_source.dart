import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';

/// The two scan-session calls a phone makes. Neither carries the pharmacy's
/// bearer token: the phone proves itself with the pairing token from the QR
/// code, then with the device token it was given in return.
class ScanSessionRemoteDataSource {
  final Dio _dio;

  const ScanSessionRemoteDataSource(this._dio);

  Future<Response<dynamic>> pair({
    required String sessionId,
    required String pairingToken,
    required String deviceName,
  }) {
    return _dio.post(
      '${ApiConstants.pharmacyScanSessions}/$sessionId/pair',
      data: {'device_name': deviceName},
      options: Options(headers: {'X-Scan-Token': pairingToken}),
    );
  }

  Future<Response<dynamic>> sendBarcode({
    required String sessionId,
    required String deviceToken,
    required String barcode,
  }) {
    return _dio.post(
      '${ApiConstants.pharmacyScanSessions}/$sessionId/barcode',
      data: {'barcode': barcode},
      options: Options(headers: {'X-Device-Token': deviceToken}),
    );
  }
}
