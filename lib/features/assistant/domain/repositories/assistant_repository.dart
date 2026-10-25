import '../../../../core/helpers/api_result.dart';
import '../entities/assistant_reply.dart';

abstract class AssistantRepository {
  /// `POST /patient/assistant/chat`. [latitude]/[longitude] are optional and
  /// let the server order the suggested pharmacies by distance.
  Future<ApiResult<AssistantReply>> sendMessage({
    required String token,
    required String message,
    double? latitude,
    double? longitude,
  });
}
