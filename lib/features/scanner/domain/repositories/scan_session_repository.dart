import '../../../../core/helpers/api_result.dart';
import '../entities/scan_pairing.dart';

/// The phone's side of a scan session: join it, then send it barcodes. The web
/// sales screen creates the session and reads what arrives.
abstract interface class ScanSessionRepository {
  /// Joins the session with the token from its QR code.
  Future<ApiResult<PairedScanner>> pair({
    required ScanPairing pairing,
    required String deviceName,
  });

  /// Sends one scanned barcode to the session. A session that ended answers a
  /// failure with status 410.
  Future<ApiResult<void>> sendBarcode({
    required PairedScanner scanner,
    required String barcode,
  });
}
