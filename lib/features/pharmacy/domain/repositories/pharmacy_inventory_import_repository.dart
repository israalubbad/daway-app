import 'dart:typed_data';

import '../../../../core/helpers/api_result.dart';
import '../entities/inventory_import_preview.dart';

/// The stock-file import: upload and analyse a spreadsheet, then confirm or
/// drop it (`/pharmacy/inventory/import`).
abstract class PharmacyInventoryImportRepository {
  Future<ApiResult<InventoryImportPreview>> preview({
    required String token,
    required String filePath,
  });

  /// The import spreadsheet template (`GET /pharmacy/inventory/import/template`), as bytes.
  Future<ApiResult<Uint8List>> downloadTemplate({required String token});

  Future<ApiResult<void>> commit({required String token, required String importId});

  Future<ApiResult<void>> cancel({required String token, required String importId});
}
