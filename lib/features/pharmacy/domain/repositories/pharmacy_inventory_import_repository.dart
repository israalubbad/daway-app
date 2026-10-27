import '../../../../core/helpers/api_result.dart';
import '../entities/inventory_import_preview.dart';

/// The stock-file import: upload and analyse a spreadsheet, then confirm or
/// drop it (`/pharmacy/inventory/import`).
abstract class PharmacyInventoryImportRepository {
  Future<ApiResult<InventoryImportPreview>> preview({
    required String token,
    required String filePath,
  });

  Future<ApiResult<void>> commit({required String token, required int importId});

  Future<ApiResult<void>> cancel({required String token, required int importId});
}
