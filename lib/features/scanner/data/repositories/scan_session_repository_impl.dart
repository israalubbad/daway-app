import '../../../../core/erroring/error_handler.dart';
import '../../../../core/erroring/failure.dart';
import '../../../../core/helpers/api_result.dart';
import '../../domain/entities/scan_pairing.dart';
import '../../domain/repositories/scan_session_repository.dart';
import '../datasources/scan_session_remote_data_source.dart';

import '../../../../core/localization/translations.dart';

class ScanSessionRepositoryImpl implements ScanSessionRepository {
  final ScanSessionRemoteDataSource _remote;

  const ScanSessionRepositoryImpl(this._remote);

  @override
  Future<ApiResult<PairedScanner>> pair({
    required ScanPairing pairing,
    required String deviceName,
  }) async {
    try {
      final response = await _remote.pair(
        sessionId: pairing.sessionId,
        pairingToken: pairing.pairingToken,
        deviceName: deviceName,
      );
      final body = response.data;
      final data = body is Map<String, dynamic> ? body['data'] : null;
      final deviceToken = data is Map<String, dynamic> ? data['device_token'] : null;
      if (deviceToken is! String || deviceToken.isEmpty) {
        return ApiError(ApiFailure(message: 'تعذر إتمام الاقتران، حاول مرة أخرى'.tr));
      }
      return Success(PairedScanner(sessionId: pairing.sessionId, deviceToken: deviceToken));
    } catch (e) {
      return ApiError(mapExceptionToFailure(e));
    }
  }

  @override
  Future<ApiResult<void>> sendBarcode({
    required PairedScanner scanner,
    required String barcode,
  }) async {
    try {
      await _remote.sendBarcode(
        sessionId: scanner.sessionId,
        deviceToken: scanner.deviceToken,
        barcode: barcode,
      );
      return const Success(null);
    } catch (e) {
      return ApiError(mapExceptionToFailure(e));
    }
  }
}
