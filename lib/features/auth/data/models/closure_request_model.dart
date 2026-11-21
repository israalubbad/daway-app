import '../../../../core/helpers/json_parsing.dart';
import '../../../../core/helpers/server_timestamp.dart';
import '../../domain/entities/closure_request.dart';

/// A pharmacy's closure request as `/pharmacy/account/closure-request` sends
/// it. The response shape has not been seen (the Postman collection has no
/// saved example), so the record is read from `data` or from a nested
/// `closure_request`/`request`, and every field of it is optional.
class ClosureRequestModel {
  const ClosureRequestModel._();

  /// The request in a response body, or null when the body carries none (the
  /// pharmacy never asked).
  static ClosureRequest? fromResponse(Object? body) {
    final data = jsonMap(jsonMap(body)?['data']);
    final record = jsonMap(data?['closure_request']) ?? jsonMap(data?['request']) ?? data;
    if (record == null) return null;
    return ClosureRequest(
      status: _status(jsonString(record['status'])),
      reason: jsonString(record['reason']),
      requestedAt: tryParseServerTimestamp(jsonString(record['created_at'])),
    );
  }

  /// A request with no status yet is a request just sent, so it is waiting.
  static ClosureRequestStatus _status(String? raw) {
    final status = raw?.toLowerCase();
    if (status == null) return ClosureRequestStatus.pending;
    bool has(List<String> words) => words.any(status.contains);
    if (has(['reject', 'declin', 'denied', 'refus', 'cancel'])) return ClosureRequestStatus.rejected;
    if (has(['pend', 'await', 'wait', 'new', 'review'])) return ClosureRequestStatus.pending;
    if (has(['approv', 'accept', 'clos', 'complet', 'done'])) return ClosureRequestStatus.approved;
    return ClosureRequestStatus.other;
  }
}
