import 'package:daway_app/features/auth/data/models/closure_request_model.dart';
import 'package:daway_app/features/auth/domain/entities/closure_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads the request out of data', () {
    final request = ClosureRequestModel.fromResponse({
      'success': true,
      'data': {
        'id': 5,
        'status': 'pending',
        'reason': 'إغلاق نهائي',
        'created_at': '2026-11-09T10:00:00.000000Z',
      },
    })!;

    expect(request.status, ClosureRequestStatus.pending);
    expect(request.reason, 'إغلاق نهائي');
    expect(request.requestedAt, DateTime.utc(2026, 11, 9, 10).toLocal());
  });

  test('reads a request nested under closure_request', () {
    final request = ClosureRequestModel.fromResponse({
      'data': {
        'closure_request': {'status': 'approved'},
      },
    })!;

    expect(request.status, ClosureRequestStatus.approved);
  });

  test('no data means the pharmacy never asked', () {
    expect(ClosureRequestModel.fromResponse({'success': true, 'data': null}), isNull);
    expect(ClosureRequestModel.fromResponse(null), isNull);
    expect(ClosureRequestModel.fromResponse('not a map'), isNull);
  });

  test('a record without a status is a request just sent, so it is waiting', () {
    final request = ClosureRequestModel.fromResponse({
      'data': {'id': 1},
    })!;

    expect(request.status, ClosureRequestStatus.pending);
  });

  test('maps the statuses an admin decision may use', () {
    ClosureRequestStatus read(String status) => ClosureRequestModel.fromResponse({
          'data': {'status': status},
        })!.status;

    expect(read('pending_review'), ClosureRequestStatus.pending);
    expect(read('rejected'), ClosureRequestStatus.rejected);
    expect(read('declined'), ClosureRequestStatus.rejected);
    expect(read('approved'), ClosureRequestStatus.approved);
    expect(read('closed'), ClosureRequestStatus.approved);
    expect(read('something_else'), ClosureRequestStatus.other);
  });

  test('only a waiting or accepted request blocks a new one', () {
    expect(const ClosureRequest(status: ClosureRequestStatus.pending).blocksNewRequest, isTrue);
    expect(const ClosureRequest(status: ClosureRequestStatus.approved).blocksNewRequest, isTrue);
    expect(const ClosureRequest(status: ClosureRequestStatus.rejected).blocksNewRequest, isFalse);
    expect(const ClosureRequest(status: ClosureRequestStatus.other).blocksNewRequest, isFalse);
  });
}
