import '../../../../core/erroring/error_handler.dart';
import '../../../../core/helpers/api_result.dart';
import '../../domain/entities/assistant_reply.dart';
import '../../domain/repositories/assistant_repository.dart';
import '../datasources/assistant_remote_data_source.dart';
import '../models/assistant_reply_model.dart';

class AssistantRepositoryImpl implements AssistantRepository {
  final AssistantRemoteDataSource _remoteDataSource;

  const AssistantRepositoryImpl(this._remoteDataSource);

  @override
  Future<ApiResult<AssistantReply>> sendMessage({
    required String token,
    required String message,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await _remoteDataSource.sendMessage(
        token: token,
        message: message,
        latitude: latitude,
        longitude: longitude,
      );
      final body = response.data;
      if (body is! Map<String, dynamic>) {
        throw FormatException('Unexpected POST /patient/assistant/chat response: $body');
      }
      return Success(AssistantReplyModel.fromJson(body));
    } catch (e) {
      return ApiError(mapExceptionToFailure(e));
    }
  }
}
