import 'package:dio/dio.dart';
import '../../../../core/networking/auth_options.dart';

import '../../../../core/constants/api_constants.dart';

class PharmacyInventoryImportRemoteDataSource {
  final Dio _dio;

  const PharmacyInventoryImportRemoteDataSource(this._dio);


  Future<Response<dynamic>> preview({required String token, required String filePath}) async {
    final form = FormData.fromMap({'file': await MultipartFile.fromFile(filePath)});
    return _dio.post(
      ApiConstants.pharmacyInventoryImport,
      data: form,
      options: authOptions(token),
    );
  }

  Future<Response<dynamic>> downloadTemplate({required String token}) {
    return _dio.get(
      '${ApiConstants.pharmacyInventoryImport}/template',
      options: Options(headers: {'Authorization': 'Bearer $token'}, responseType: ResponseType.bytes),
    );
  }

  Future<Response<dynamic>> commit({required String token, required String importId}) {
    return _dio.post('${ApiConstants.pharmacyInventoryImport}/$importId/commit', options: authOptions(token));
  }

  Future<Response<dynamic>> cancel({required String token, required String importId}) {
    return _dio.post('${ApiConstants.pharmacyInventoryImport}/$importId/cancel', options: authOptions(token));
  }
}
