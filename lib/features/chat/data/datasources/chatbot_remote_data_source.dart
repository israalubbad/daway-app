import 'package:dio/dio.dart';

class ChatbotRemoteDataSource {
  final Dio _dio;

  const ChatbotRemoteDataSource(this._dio);

  Future<Response<dynamic>> chat({required String token, required String message}) {
    return _dio.post(
      '/patient/assistant/chat',
      data: {'message': message},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }
}
