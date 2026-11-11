import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/erroring/failure.dart';
import '../../../../core/helpers/api_result.dart';
import '../../domain/entities/scan_pairing.dart';
import '../../domain/usecases/scan_session_usecases.dart';
import 'phone_scanner_state.dart';

import '../../../../core/localization/translations.dart';

/// The phone as the web sales screen's barcode scanner: reads the QR code on
/// that screen to join its scan session, then sends every barcode the camera
/// reads to it.
class PhoneScannerCubit extends Cubit<PhoneScannerState> {
  final PairScannerUseCase _pair;
  final SendScannedBarcodeUseCase _send;
  final DateTime Function() _now;

  PhoneScannerCubit(this._pair, this._send, {DateTime Function()? now})
    : _now = now ?? DateTime.now,
      super(const PhoneScannerState());

  static const _deviceName = 'Dawak app';

  /// The camera keeps reporting a code for as long as it is in front of it: the
  /// same one is taken once in this long.
  static const _repeatWindow = Duration(seconds: 3);

  PairedScanner? _scanner;
  String? _lastRaw;
  DateTime? _lastRawAt;

  bool _isRepeat(String raw) {
    final at = _lastRawAt;
    final repeated = raw == _lastRaw && at != null && _now().difference(at) < _repeatWindow;
    _lastRaw = raw;
    _lastRawAt = _now();
    return repeated;
  }

  /// A QR code was read while waiting to pair.
  Future<void> qrDetected(String raw) async {
    if (state.phase != PhoneScannerPhase.pairing || state.isBusy || _isRepeat(raw)) return;
    emit(state.copyWith(isBusy: true, clearMessage: true));
    final result = await _pair(qrContent: raw, deviceName: _deviceName);
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        _scanner = data;
        emit(
          state.copyWith(
            phase: PhoneScannerPhase.scanning,
            isBusy: false,
            isError: false,
            message: 'تم الاقتران، وجّه الكاميرا نحو الباركود'.tr,
          ),
        );
      case ApiError(:final failure):
        emit(state.copyWith(isBusy: false, isError: true, message: _pairingMessage(failure)));
    }
  }

  /// A barcode was read while paired.
  Future<void> barcodeDetected(String barcode) async {
    final scanner = _scanner;
    if (scanner == null || state.phase != PhoneScannerPhase.scanning) return;
    if (state.isBusy || _isRepeat(barcode)) return;
    emit(state.copyWith(isBusy: true));
    final result = await _send(scanner: scanner, barcode: barcode);
    if (isClosed) return;
    switch (result) {
      case Success():
        emit(
          state.copyWith(
            isBusy: false,
            isError: false,
            lastBarcode: barcode,
            sentCount: state.sentCount + 1,
            message: 'تم إرسال الباركود'.tr,
          ),
        );
      case ApiError(:final failure):
        // 410: the session ran out (it lasts minutes); 403 / 401: this phone is
        // no longer the paired one. Either way there is nothing to send to.
        final over = [410, 403, 401].contains(_statusOf(failure));
        emit(
          state.copyWith(
            phase: over ? PhoneScannerPhase.ended : state.phase,
            isBusy: false,
            isError: true,
            message: over ? 'انتهت جلسة المسح، ابدأ جلسة جديدة من الموقع'.tr : failure.message,
          ),
        );
    }
  }

  /// Back to waiting for a QR code, after the session ended.
  void restart() {
    _scanner = null;
    _lastRaw = null;
    _lastRawAt = null;
    emit(const PhoneScannerState());
  }

  int? _statusOf(Failure failure) => failure is ApiFailure ? failure.statusCode : null;

  String _pairingMessage(Failure failure) {
    return switch (_statusOf(failure)) {
      409 => 'هناك جهاز آخر مقترن بهذه الجلسة، وافق على الاستبدال من شاشة الموقع'.tr,
      410 || 404 => 'انتهت جلسة المسح، أنشئ رمزاً جديداً من الموقع'.tr,
      _ => failure.message,
    };
  }
}
