import '../../../../core/helpers/server_timestamp.dart';
import '../../domain/entities/pharmacy_inquiry.dart';

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
    final pharmacy = _map(json['pharmacy']);
    final medicine = _map(json['medicine']);

    return PharmacyInquiryModel(
      id: _int(json['id']) ?? 0,
      pharmacyId: _int(pharmacy?['id']) ?? 0,
      medicineId: _int(medicine?['id']) ?? 0,
      medicineName: _string(medicine?['trade_name']),
      pharmacyName: _string(pharmacy?['pharmacy_name']) ?? _string(pharmacy?['name']),
      message: _string(json['message']) ?? '',
      lastMessage: _lastMessageText(json['last_message']),
      unreadCount: _int(json['unread_messages_count']) ?? 0,
      reply: _string(json['reply']),
      status: InquiryStatus.fromApi(_string(json['status'])),
      createdAt: tryParseServerTimestamp(_string(json['created_at'])) ?? DateTime.now(),
      repliedAt: tryParseServerTimestamp(_string(json['replied_at'])),
    );
  }

  // A field of an unexpected type reads as missing instead of failing the
  // whole list: one odd row must not hide every conversation.
  static Map<String, dynamic>? _map(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : null;

  static int? _int(Object? value) =>
      value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');

  static String? _string(Object? value) => value is String ? value : null;

  /// `last_message` may be the message text or the message object.
  static String? _lastMessageText(Object? value) {
    if (value is String) return value.isEmpty ? null : value;
    if (value is Map) {
      final text = value['message'];
      if (text is String && text.isNotEmpty) return text;
      if (value['media_url'] != null) return 'صورة';
    }
    return null;
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
