import '../../../../core/helpers/api_result.dart';
import '../../../chat/domain/entities/chat_conversation.dart';
import '../../../chat/domain/usecases/group_conversations.dart';
import '../entities/inquiry.dart';
import 'get_pharmacy_inquiries_usecase.dart';

import '../../../../core/localization/translations.dart';
/// The pharmacy's conversations: one per patient, however many inquiries they

/// have sent, most recently active first.
class GetPatientConversationsUseCase implements ConversationsSource {
  final GetPharmacyInquiriesUseCase _getInquiriesUseCase;

  const GetPatientConversationsUseCase(this._getInquiriesUseCase);

  @override
  Future<ApiResult<List<ChatConversation>>> call() async {
    final result = await _getInquiriesUseCase();
    return switch (result) {
      ApiError(:final failure) => ApiError(failure),
      Success(:final data) => Success(_group(data.inquiries)),
    };
  }

  // The patient id when the API gives one, otherwise the name.
  List<ChatConversation> _group(List<Inquiry> inquiries) => groupConversations(
    inquiries,
    groupKey: (inquiry) => inquiry.patientId ?? inquiry.patientName,
    id: (inquiry) => inquiry.id,
    createdAt: (inquiry) => inquiry.createdAt,
    unreadCount: (inquiry) => inquiry.unreadCount,
    title: (latest) => latest.patientName.isEmpty ? 'مريض'.tr : latest.patientName,
    lastText: (latest) => latest.lastMessage ?? latest.message,
  );
}
