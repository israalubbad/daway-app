import 'package:daway_app/core/erroring/failure.dart';
import 'package:daway_app/core/helpers/api_result.dart';
import 'package:daway_app/features/scanner/data/datasources/scan_session_remote_data_source.dart';
import 'package:daway_app/features/scanner/data/repositories/scan_session_repository_impl.dart';
import 'package:daway_app/features/scanner/domain/entities/scan_pairing.dart';
import 'package:daway_app/features/scanner/domain/repositories/scan_session_repository.dart';
import 'package:daway_app/features/scanner/domain/usecases/scan_session_usecases.dart';
import 'package:daway_app/features/scanner/presentation/cubit/phone_scanner_cubit.dart';
import 'package:daway_app/features/scanner/presentation/cubit/phone_scanner_state.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

const _qr = 'daway://pair?sid=3f1c0a52-aaaa-bbbb-cccc-1234567890ab&token=abcdef0123456789';

class _FakeRepository implements ScanSessionRepository {
  ApiResult<PairedScanner> pairResult =
      const Success(PairedScanner(sessionId: 'sid', deviceToken: 'dev-token'));
  ApiResult<void> sendResult = const Success(null);
  ScanPairing? pairedWith;
  final List<String> sent = [];

  @override
  Future<ApiResult<PairedScanner>> pair({
    required ScanPairing pairing,
    required String deviceName,
  }) async {
    pairedWith = pairing;
    return pairResult;
  }

  @override
  Future<ApiResult<void>> sendBarcode({
    required PairedScanner scanner,
    required String barcode,
  }) async {
    sent.add(barcode);
    return sendResult;
  }
}

class _StubRemote extends ScanSessionRemoteDataSource {
  Response<dynamic>? pairResponse;
  Map<String, String>? lastPairHeaders;
  Map<String, String>? lastSendHeaders;
  String? lastSessionId;

  _StubRemote() : super(Dio());

  @override
  Future<Response<dynamic>> pair({
    required String sessionId,
    required String pairingToken,
    required String deviceName,
  }) async {
    lastSessionId = sessionId;
    lastPairHeaders = {'X-Scan-Token': pairingToken};
    return pairResponse!;
  }

  @override
  Future<Response<dynamic>> sendBarcode({
    required String sessionId,
    required String deviceToken,
    required String barcode,
  }) async {
    lastSendHeaders = {'X-Device-Token': deviceToken};
    return Response(requestOptions: RequestOptions(), data: {'success': true}, statusCode: 200);
  }
}

void main() {
  group('ScanPairing', () {
    test('reads the session and the token from the QR link', () {
      final pairing = ScanPairing.tryParse(_qr)!;

      expect(pairing.sessionId, '3f1c0a52-aaaa-bbbb-cccc-1234567890ab');
      expect(pairing.pairingToken, 'abcdef0123456789');
    });

    test('anything that is not a pairing link is null', () {
      expect(ScanPairing.tryParse('https://example.com'), isNull);
      expect(ScanPairing.tryParse('daway://pair?sid=x'), isNull);
      expect(ScanPairing.tryParse('6221031234567'), isNull);
      expect(ScanPairing.tryParse(''), isNull);
    });
  });

  group('use cases', () {
    test('a code that is not a pairing link is refused without a request', () async {
      final repository = _FakeRepository();

      final result = await PairScannerUseCase(repository)(qrContent: 'nope', deviceName: 'd');

      expect(result, isA<ApiError<PairedScanner>>());
      expect(repository.pairedWith, isNull);
    });

    test('an empty or over-long barcode is not sent', () async {
      final repository = _FakeRepository();
      const scanner = PairedScanner(sessionId: 's', deviceToken: 't');
      final send = SendScannedBarcodeUseCase(repository);

      expect(await send(scanner: scanner, barcode: '   '), isA<ApiError<void>>());
      expect(await send(scanner: scanner, barcode: '1' * 33), isA<ApiError<void>>());
      await send(scanner: scanner, barcode: ' 6221031234567 ');

      expect(repository.sent, ['6221031234567']);
    });
  });

  group('repository', () {
    test('pairing takes the device token from data.device_token', () async {
      final remote = _StubRemote()
        ..pairResponse = Response(
          requestOptions: RequestOptions(),
          data: {
            'success': true,
            'data': {'name': 'Dawak app', 'device_token': 'secret-device-token'},
          },
          statusCode: 200,
        );
      final repository = ScanSessionRepositoryImpl(remote);

      final result = await repository.pair(
        pairing: ScanPairing.tryParse(_qr)!,
        deviceName: 'Dawak app',
      );

      final scanner = (result as Success<PairedScanner>).data;
      expect(scanner.deviceToken, 'secret-device-token');
      expect(scanner.sessionId, '3f1c0a52-aaaa-bbbb-cccc-1234567890ab');
      expect(remote.lastPairHeaders, {'X-Scan-Token': 'abcdef0123456789'});
    });

    test('a pairing answer without a device token is a failure', () async {
      final remote = _StubRemote()
        ..pairResponse = Response(
          requestOptions: RequestOptions(),
          data: {'success': true, 'data': {'name': 'x'}},
          statusCode: 200,
        );

      final result = await ScanSessionRepositoryImpl(remote).pair(
        pairing: ScanPairing.tryParse(_qr)!,
        deviceName: 'd',
      );

      expect(result, isA<ApiError<PairedScanner>>());
    });
  });

  group('PhoneScannerCubit', () {
    late _FakeRepository repository;
    late DateTime now;
    late PhoneScannerCubit cubit;

    setUp(() {
      repository = _FakeRepository();
      now = DateTime(2026, 11, 10, 12);
      cubit = PhoneScannerCubit(
        PairScannerUseCase(repository),
        SendScannedBarcodeUseCase(repository),
        now: () => now,
      );
    });

    tearDown(() => cubit.close());

    test('starts waiting for the QR code', () {
      expect(cubit.state.phase, PhoneScannerPhase.pairing);
    });

    test('a pairing QR joins the session and moves on to scanning', () async {
      await cubit.qrDetected(_qr);

      expect(cubit.state.phase, PhoneScannerPhase.scanning);
      expect(repository.pairedWith!.sessionId, '3f1c0a52-aaaa-bbbb-cccc-1234567890ab');
    });

    test('a QR that is not ours says so and keeps waiting', () async {
      await cubit.qrDetected('https://example.com');

      expect(cubit.state.phase, PhoneScannerPhase.pairing);
      expect(cubit.state.isError, isTrue);
      expect(repository.pairedWith, isNull);
    });

    test('another device already paired is explained', () async {
      repository.pairResult = const ApiError(ApiFailure(message: 'conflict', statusCode: 409));

      await cubit.qrDetected(_qr);

      expect(cubit.state.phase, PhoneScannerPhase.pairing);
      expect(cubit.state.message, contains('جهاز آخر'));
    });

    test('barcodes are only sent once paired', () async {
      await cubit.barcodeDetected('6221031234567');

      expect(repository.sent, isEmpty);
    });

    test('a barcode is sent and counted; the same one again at once is ignored', () async {
      await cubit.qrDetected(_qr);

      await cubit.barcodeDetected('6221031234567');
      await cubit.barcodeDetected('6221031234567');
      expect(repository.sent, ['6221031234567']);
      expect(cubit.state.sentCount, 1);

      // Later, scanning it again is a new scan.
      now = now.add(const Duration(seconds: 5));
      await cubit.barcodeDetected('6221031234567');
      expect(repository.sent, hasLength(2));
      expect(cubit.state.sentCount, 2);
    });

    test('an ended session (410) stops the scanning and offers a new pairing', () async {
      await cubit.qrDetected(_qr);
      repository.sendResult = const ApiError(ApiFailure(message: 'gone', statusCode: 410));

      await cubit.barcodeDetected('6221031234567');

      expect(cubit.state.phase, PhoneScannerPhase.ended);

      cubit.restart();
      expect(cubit.state.phase, PhoneScannerPhase.pairing);
    });

    test('a network failure keeps scanning', () async {
      await cubit.qrDetected(_qr);
      repository.sendResult = const ApiError(NetworkFailure('offline'));

      await cubit.barcodeDetected('6221031234567');

      expect(cubit.state.phase, PhoneScannerPhase.scanning);
      expect(cubit.state.isError, isTrue);
    });
  });
}
