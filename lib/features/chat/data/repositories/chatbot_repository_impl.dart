import '../../../../core/erroring/error_handler.dart';
import '../../../../core/helpers/api_result.dart';
import '../../domain/repositories/chatbot_repository.dart';
import '../datasources/chatbot_remote_data_source.dart';

/// Shown when the assistant answers but there is no text to show (for
/// example `success: false` for a greeting that is not a medicine search).
const _noAnswerMessage = 'لم أفهم سؤالك. جرّب أن تكتب اسم الدواء الذي تبحث عنه.';

class ChatbotRepositoryImpl implements ChatbotRepository {
  final ChatbotRemoteDataSource _remoteDataSource;

  const ChatbotRepositoryImpl(this._remoteDataSource);

  @override
  Future<ApiResult<String>> send({required String token, required String message}) async {
    try {
      final response = await _remoteDataSource.chat(token: token, message: message);
      return Success(replyText(response.data) ?? _noAnswerMessage);
    } catch (e) {
      return ApiError(mapExceptionToFailure(e));
    }
  }

  /// The assistant's text from a response body. The reply field is not
  /// documented, so the usual names are tried at the top level and under
  /// `data`; null when none holds text.
  static String? replyText(Object? body) {
    const keys = ['reply', 'message', 'answer', 'response', 'text'];
    String? fromNode(Object? node) {
      if (node is String && node.trim().isNotEmpty) return node.trim();
      if (node is! Map) return null;
      for (final key in keys) {
        final value = node[key];
        if (value is String && value.trim().isNotEmpty) return value.trim();
      }
      return null;
    }

    if (body is! Map) return fromNode(body);
    return fromNode(body) ?? fromNode(body['data']);
  }
}
