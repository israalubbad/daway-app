import '../../../../core/erroring/failure.dart';
import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../entities/chatbot_reply.dart';
import '../repositories/chatbot_repository.dart';

class SendChatbotMessageUseCase {
  final ChatbotRepository _repository;
  final SessionRepository _sessionRepository;

  const SendChatbotMessageUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<ChatbotReply>> call(String message) async {
    final session = await _sessionRepository.getSession();
    if (session == null) {
      return ApiError(
        ApiFailure(message: sessionExpiredMessage),
      );
    }
    return _repository.send(token: session.token, message: message);
  }
}
