import '../../domain/entities/payment.dart';

String? _text(Object? value) {
  final text = value?.toString().trim();
  return (text == null || text.isEmpty) ? null : text;
}

double? _number(Object? value) =>
    value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '');

/// Tolerant of the bank field names: the bank row shape is only known from
/// the API docs, not from a captured response.
PaymentBank? parsePaymentBank(Object? json) {
  if (json is! Map<String, dynamic>) return null;
  final id = (json['id'] as num?)?.toInt();
  final name = _text(json['bank_name']) ?? _text(json['name']) ?? _text(json['title']);
  if (id == null || name == null) return null;
  return PaymentBank(
    id: id,
    name: name,
    accountHolder: _text(json['account_holder']) ??
        _text(json['account_name']) ??
        _text(json['holder_name']),
    accountNumber: _text(json['account_number']) ?? _text(json['account_no']),
    iban: _text(json['iban']),
    notes: _text(json['instructions']) ?? _text(json['notes']),
  );
}

List<PaymentBank> parsePaymentBanks(Object? json) =>
    json is List ? [for (final row in json) ?parsePaymentBank(row)] : const [];

PaymentSummary parsePaymentSummary(Map<String, dynamic> data) {
  final latest = data['latest_submission'];
  return PaymentSummary(
    status: _text(data['payment_status']) ?? 'pending',
    canSubmitReceipt: data['can_submit_receipt'] == true,
    banks: parsePaymentBanks(data['banks']),
    grandTotal: _number(data['grand_total']),
    deliveryFee: _number(data['delivery_fee']),
    latestSubmissionId: latest is Map<String, dynamic> ? (latest['id'] as num?)?.toInt() : null,
  );
}

OrderTracking parseOrderTracking(Map<String, dynamic> data) {
  final histories = data['status_histories'];
  return OrderTracking(
    status: _text(data['status']) ?? '',
    steps: histories is List
        ? [
            for (final row in histories)
              if (row is Map<String, dynamic> && _text(row['status']) != null)
                TrackingStep(
                  status: _text(row['status'])!,
                  at: DateTime.tryParse(_text(row['created_at']) ?? '')?.toLocal(),
                ),
          ]
        : const [],
  );
}
