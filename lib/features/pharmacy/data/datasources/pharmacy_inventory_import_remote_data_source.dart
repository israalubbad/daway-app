import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';

class PharmacyInventoryImportRemoteDataSource {
  final Dio _dio;

  const PharmacyInventoryImportRemoteDataSource(this._dio);

  Options _auth(String token) => Options(headers: {'Authorization': 'Bearer $token'});

  Future<Response<dynamic>> preview({required String token, required String filePath}) async {
    final form = FormData.fromMap({'file': await MultipartFile.fromFile(filePath)});
    return _dio.post(
      ApiConstants.pharmacyInventoryImport,
      data: form,
      options: _auth(token),
    );
  }

  Future<Response<dynamic>> commit({required String token, required int importId}) {
    return _dio.post('${ApiConstants.pharmacyInventoryImport}/$importId/commit', options: _auth(token));
  }

  Future<Response<dynamic>> cancel({required String token, required int importId}) {
    return _dio.post('${ApiConstants.pharmacyInventoryImport}/$importId/cancel', options: _auth(token));
  }
}
