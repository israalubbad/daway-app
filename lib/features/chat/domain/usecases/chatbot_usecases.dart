import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../entities/chatbot_reply.dart';
import '../repositories/chatbot_repository.dart';
import '../../../auth/domain/usecases/with_session_token.dart';

class SendChatbotMessageUseCase {
  final ChatbotRepository _repository;
  final SessionRepository _sessionRepository;

  const SendChatbotMessageUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<ChatbotReply>> call(String message) {
    return withSessionToken(
      _sessionRepository,
      (token) => _repository.send(token: token, message: message),
    );
  }
}
