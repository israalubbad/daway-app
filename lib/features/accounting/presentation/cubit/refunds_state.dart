import '../../domain/entities/refund_record.dart';

sealed class RefundsState {
  const RefundsState();
}

class RefundsLoading extends RefundsState {
  const RefundsLoading();
}

class RefundsLoadFailure extends RefundsState {
  final String message;

  const RefundsLoadFailure(this.message);
}

class RefundsLoaded extends RefundsState {
  final List<RefundRecord> all;
  final String query;
  final RefundStatus? status;

  const RefundsLoaded({required this.all, this.query = '', this.status});

  List<RefundRecord> get visible {
    final q = query.trim().toLowerCase();
    return [
      for (final refund in all)
        if ((q.isEmpty ||
                refund.number.toLowerCase().contains(q) ||
                refund.invoiceNumber.toLowerCase().contains(q) ||
                (refund.customerName ?? '').toLowerCase().contains(q)) &&
            (status == null || refund.status == status))
          refund,
    ];
  }

  RefundsLoaded copyWith({
    List<RefundRecord>? all,
    String? query,
    RefundStatus? status,
    bool clearStatus = false,
  }) {
    return RefundsLoaded(
      all: all ?? this.all,
      query: query ?? this.query,
      status: clearStatus ? null : (status ?? this.status),
    );
  }
}
