import '../../../../core/helpers/json_parsing.dart';
import '../../../../core/helpers/server_timestamp.dart';
import '../../domain/entities/pharmacy_inquiry.dart';
import '../../../chat/domain/entities/last_message_text.dart';

class PharmacyInquiryModel {

  final int id;
  final int pharmacyId;
  final int medicineId;
  final String? medicineName;
  final String? pharmacyName;
  final String message;
  final String? lastMessage;
  final int unreadCount;
  final String? reply;
  final InquiryStatus status;
  final DateTime createdAt;
  final DateTime? repliedAt;

  const PharmacyInquiryModel({
    required this.id,
    required this.pharmacyId,
    required this.medicineId,
    this.medicineName,
    this.pharmacyName,
    required this.message,
    this.lastMessage,
    this.unreadCount = 0,
    this.reply,
    required this.status,
    required this.createdAt,
    this.repliedAt,
  });

  factory PharmacyInquiryModel.fromJson(Map<String, dynamic> json) {
    final pharmacy = jsonMap(json['pharmacy']);
    final medicine = jsonMap(json['medicine']);

    return PharmacyInquiryModel(
      id: jsonInt(json['id']) ?? 0,
      pharmacyId: jsonInt(pharmacy?['id']) ?? 0,
      medicineId: jsonInt(medicine?['id']) ?? 0,
      medicineName: jsonString(medicine?['trade_name']),
      pharmacyName: jsonString(pharmacy?['pharmacy_name']) ?? jsonString(pharmacy?['name']),
      message: jsonString(json['message']) ?? '',
      lastMessage: lastMessageText(json['last_message']),
      unreadCount: jsonInt(json['unread_messages_count']) ?? 0,
      reply: jsonString(json['reply']),
      status: InquiryStatus.fromApi(jsonString(json['status'])),
      createdAt: tryParseServerTimestamp(jsonString(json['created_at'])) ?? DateTime.now(),
      repliedAt: tryParseServerTimestamp(jsonString(json['replied_at'])),
    );
  }

  PharmacyInquiry toEntity() => PharmacyInquiry(
        id: id,
        pharmacyId: pharmacyId,
        medicineId: medicineId,
        medicineName: medicineName,
        pharmacyName: pharmacyName,
        message: message,
        lastMessage: lastMessage,
        unreadCount: unreadCount,
        reply: reply,
        status: status,
        createdAt: createdAt,
        repliedAt: repliedAt,
      );
}
