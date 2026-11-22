import '../../domain/entities/inquiry.dart';
import '../../../chat/domain/entities/last_message_text.dart';
import '../../../../core/helpers/json_parsing.dart';

/// Parses one entry from `GET /pharmacy/inquiries` (confirmed against a live

/// response: `id`, `status`, `message`, `created_at`, nested `user.name`,
/// nested `medicine.trade_name`). Shared by the dashboard's recent-inquiries
/// preview and the full الاستفسارات screen so both parse the same shape once.
class InquiryModel {
  final int id;
  final String message;
  final InquiryStatus status;
  final DateTime createdAt;
  final String patientName;
  final String? medicineName;
  final int unreadCount;
  final int? patientId;
  final String? lastMessage;

  const InquiryModel({
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

  factory InquiryModel.fromJson(Map<String, dynamic> json) {
    final medicine = jsonMap(json['medicine']);
    final user = jsonMap(json['user']);
    return InquiryModel(
      // A record without an id cannot be opened or answered: the callers skip it.
      id: jsonInt(json['id']) ?? (throw const FormatException('Inquiry record has no id')),
      message: jsonString(json['message']) ?? '',
      status: inquiryStatusFrom(jsonString(json['status'])),
      createdAt:
          DateTime.tryParse(jsonString(json['created_at']) ?? '') ??
          DateTime.now(),
      patientName: jsonString(user?['name']) ?? '',
      medicineName: jsonString(medicine?['trade_name']),
      unreadCount: jsonInt(json['unread_messages_count']) ?? 0,
      patientId: jsonInt(user?['id']) ?? jsonInt(json['user_id']),
      lastMessage: lastMessageText(json['last_message']),
    );
  }

  Inquiry toEntity() => Inquiry(
    id: id,
    message: message,
    status: status,
    createdAt: createdAt,
    patientName: patientName,
    medicineName: medicineName,
    unreadCount: unreadCount,
    patientId: patientId,
    lastMessage: lastMessage,
  );
}
