/// Where a pharmacy's request to close its account stands.
enum ClosureRequestStatus {
  /// Sent, and waiting for the admin's decision.
  pending,

  /// The admin accepted it; the account is being (or has been) closed.
  approved,

  /// The admin turned it down; the pharmacy may ask again.
  rejected,

  /// A status the app does not know: shown as "sent", never as a decision.
  other,
}

/// A pharmacy's request to close its account (`/pharmacy/account/closure-request`).
/// A pharmacy cannot delete itself: the request is reviewed by an admin.
class ClosureRequest {
  final ClosureRequestStatus status;
  final String? reason;
  final DateTime? requestedAt;

  const ClosureRequest({required this.status, this.reason, this.requestedAt});

  /// True while a new request would be a duplicate: one is waiting, or the
  /// admin already accepted it.
  bool get blocksNewRequest =>
      status == ClosureRequestStatus.pending || status == ClosureRequestStatus.approved;
}
