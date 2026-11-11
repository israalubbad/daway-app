import '../../../../core/erroring/failure.dart';
import '../../../../core/helpers/api_result.dart';
import '../entities/scan_pairing.dart';
import '../repositories/scan_session_repository.dart';

import '../../../../core/localization/translations.dart';

/// Joins the scan session a QR code names. Anything that is not a Daway pairing
/// link is refused without a request.
class PairScannerUseCase {
  final ScanSessionRepository _repository;

  const PairScannerUseCase(this._repository);

  Future<ApiResult<PairedScanner>> call({required String qrContent, required String deviceName}) {
    final pairing = ScanPairing.tryParse(qrContent);
    if (pairing == null) {
      return Future.value(ApiError(ApiFailure(message: 'هذا ليس رمز اقتران من دواك'.tr)));
    }
    return _repository.pair(pairing: pairing, deviceName: deviceName);
  }
}

/// Sends a scanned barcode to the session. The backend stores up to 32
/// characters and takes nothing empty.
class SendScannedBarcodeUseCase {
  final ScanSessionRepository _repository;

  const SendScannedBarcodeUseCase(this._repository);

  Future<ApiResult<void>> call({required PairedScanner scanner, required String barcode}) {
    final trimmed = barcode.trim();
    if (trimmed.isEmpty || trimmed.length > 32) {
      return Future.value(ApiError(ApiFailure(message: 'الباركود غير صالح'.tr)));
    }
    return _repository.sendBarcode(scanner: scanner, barcode: trimmed);
  }
}
