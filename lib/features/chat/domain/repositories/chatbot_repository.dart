import '../../../../core/helpers/api_result.dart';
import '../entities/chatbot_reply.dart';

abstract class ChatbotRepository {
  /// Sends [message] to the patient assistant and returns what it said, or
  /// nothing (an empty reply) when the response has none.
  Future<ApiResult<ChatbotReply>> send({
    required String token,
    required String message,
  });
}
