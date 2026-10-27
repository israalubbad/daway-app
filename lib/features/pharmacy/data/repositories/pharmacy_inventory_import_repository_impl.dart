import 'dart:typed_data';

import '../../../../core/erroring/error_handler.dart';
import '../../../../core/erroring/failure.dart';
import '../../../../core/helpers/api_result.dart';
import '../../domain/entities/inventory_import_preview.dart';
import '../../domain/repositories/pharmacy_inventory_import_repository.dart';
import '../datasources/pharmacy_inventory_import_remote_data_source.dart';
import '../models/inventory_import_preview_model.dart';

class PharmacyInventoryImportRepositoryImpl implements PharmacyInventoryImportRepository {
  final PharmacyInventoryImportRemoteDataSource _remoteDataSource;

  const PharmacyInventoryImportRepositoryImpl(this._remoteDataSource);

  @override
  Future<ApiResult<InventoryImportPreview>> preview({
    required String token,
    required String filePath,
  }) async {
    try {
      final response = await _remoteDataSource.preview(token: token, filePath: filePath);
      final json = response.data;
      if (json is! Map<String, dynamic>) {
        return const ApiError(ApiFailure(message: 'تعذر قراءة نتيجة تحليل الملف'));
      }
      final model = InventoryImportPreviewModel.fromJson(json);
      final importId = model.importId;
      if (importId == null) {
        return const ApiError(ApiFailure(message: 'تعذر قراءة نتيجة تحليل الملف'));
      }
      return Success(model.toEntity(importId));
    } catch (e) {
      return ApiError(mapExceptionToFailure(e));
    }
  }

  @override
  Future<ApiResult<Uint8List>> downloadTemplate({required String token}) async {
    try {
      final response = await _remoteDataSource.downloadTemplate(token: token);
      final bytes = response.data;
      if (bytes is! List<int> || bytes.isEmpty) {
        return const ApiError(ApiFailure(message: 'تعذر تنزيل القالب'));
      }
      return Success(Uint8List.fromList(bytes));
    } catch (e) {
      return ApiError(mapExceptionToFailure(e));
    }
  }

  @override
  Future<ApiResult<void>> commit({required String token, required String importId}) async {
    try {
      await _remoteDataSource.commit(token: token, importId: importId);
      return const Success(null);
    } catch (e) {
      return ApiError(mapExceptionToFailure(e));
    }
  }

  @override
  Future<ApiResult<void>> cancel({required String token, required String importId}) async {
    try {
      await _remoteDataSource.cancel(token: token, importId: importId);
      return const Success(null);
    } catch (e) {
      return ApiError(mapExceptionToFailure(e));
    }
  }
}
