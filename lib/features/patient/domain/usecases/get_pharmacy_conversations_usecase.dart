import '../../../../core/helpers/api_result.dart';
import '../../../chat/domain/entities/chat_conversation.dart';
import '../entities/pharmacy_inquiry.dart';
import '../../../chat/domain/usecases/group_conversations.dart';
import 'get_patient_inquiries_usecase.dart';

import '../../../../core/localization/translations.dart';

/// The patient's conversations: one per pharmacy, however many inquiries
/// (one per medicine) they have with it, most recently active first.
class GetPharmacyConversationsUseCase implements ConversationsSource {
  final GetPatientInquiriesUseCase _getInquiriesUseCase;

  const GetPharmacyConversationsUseCase(this._getInquiriesUseCase);

  @override
  Future<ApiResult<List<ChatConversation>>> call() async {
    final result = await _getInquiriesUseCase();
    return switch (result) {
      ApiError(:final failure) => ApiError(failure),
      Success(:final data) => Success(_group(data)),
    };
  }

  List<ChatConversation> _group(List<PharmacyInquiry> inquiries) => groupConversations(
    inquiries,
    groupKey: (inquiry) => inquiry.pharmacyId,
    id: (inquiry) => inquiry.id,
    createdAt: (inquiry) => inquiry.createdAt,
    unreadCount: (inquiry) => inquiry.unreadCount,
    title: (latest) => latest.pharmacyName ?? 'صيدلية'.tr,
    lastText: (latest) => latest.lastMessage ?? latest.reply ?? latest.message,
  );
}
