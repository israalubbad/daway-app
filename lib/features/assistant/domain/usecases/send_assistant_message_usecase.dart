import '../../../../core/erroring/failure.dart';
import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../entities/assistant_reply.dart';
import '../repositories/assistant_repository.dart';

class SendAssistantMessageUseCase {
  final AssistantRepository _repository;
  final SessionRepository _sessionRepository;

  const SendAssistantMessageUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<AssistantReply>> call(
    String message, {
    double? latitude,
    double? longitude,
  }) async {
    final session = await _sessionRepository.getSession();
    if (session == null) {
      return const ApiError(
        ApiFailure(message: 'انتهت صلاحية الجلسة، يرجى تسجيل الدخول مرة أخرى'),
      );
    }
    return _repository.sendMessage(
      token: session.token,
      message: message,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
