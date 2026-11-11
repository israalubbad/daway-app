enum InquiryStatus { newInquiry, answered, closed }

/// Maps the backend's `new`/`answered`/`closed` status string, defaulting
/// unrecognized values to [InquiryStatus.answered] (the least
/// attention-grabbing state) rather than crashing on an unexpected string.
InquiryStatus inquiryStatusFrom(String? raw) {
  return switch (raw) {
    'new' => InquiryStatus.newInquiry,
    'closed' => InquiryStatus.closed,
    _ => InquiryStatus.answered,
  };
}

/// A patient's inquiry to the pharmacy about a medicine's availability.
/// Shared by the home screen's "أحدث الاستفسارات" preview and the full
/// الاستفسارات management screen, so both parse the same wire shape once.
class Inquiry {
  final int id;
  final String message;
  final InquiryStatus status;
  final DateTime createdAt;
  final String patientName;
  final String? medicineName;

  /// Patient messages the pharmacy hasn't read yet (`unread_messages_count`).
  final int unreadCount;

  /// The patient's user id and the thread's latest chat message text (null
  /// when the API omits them) — used to group inquiries per patient.
  final int? patientId;
  final String? lastMessage;

  const Inquiry({
    required this.id,
    required this.message,
    required this.status,
    required this.createdAt,
    required this.patientName,
    this.medicineName,
    this.unreadCount = 0,
    this.patientId,
    this.lastMessage,
  });
}
enum InquiryStatusFilter { all, newInquiry, answered, closed }

/// The full response shape of `GET /pharmacy/inquiries`: the page of
/// inquiries plus the backend's own status counts (`counts.new/answered/
/// closed`) — kept separate from a client-side tally of [inquiries] since
/// that list may not include every inquiry (pagination), while the counts
/// always reflect the true totals.
class InquiriesOverview {
  final List<Inquiry> inquiries;
  final int newCount;
  final int answeredCount;
  final int closedCount;

  const InquiriesOverview({
    required this.inquiries,
    required this.newCount,
    required this.answeredCount,
    required this.closedCount,
  });
}
