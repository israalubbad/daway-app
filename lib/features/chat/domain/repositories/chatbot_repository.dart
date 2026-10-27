import '../../../../core/helpers/api_result.dart';

abstract class ChatbotRepository {
  /// Sends [message] to the patient assistant and returns its reply text.
  Future<ApiResult<String>> send({required String token, required String message});
}
