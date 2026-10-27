import '../../domain/entities/inventory_import_preview.dart';

/// Parsed from the response of `POST /pharmacy/inventory/import`. The
/// collection documents no response for it, so the field names here
/// (`import_id`/`id`, `total`, `new`, `updated`, `errors`) are a best guess
/// that has not been checked against a live pharmacy login — every count falls
/// back to 0, and a response with no id is rejected by the repository.
class InventoryImportPreviewModel {
  final int? importId;
  final int totalCount;
  final int newCount;
  final int updatedCount;
  final int errorCount;

  const InventoryImportPreviewModel({
    required this.importId,
    required this.totalCount,
    required this.newCount,
    required this.updatedCount,
    required this.errorCount,
  });

  factory InventoryImportPreviewModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final source = data is Map<String, dynamic> ? data : json;
    final summary = source['summary'] is Map<String, dynamic>
        ? source['summary'] as Map<String, dynamic>
        : source;

    int count(List<String> keys) {
      for (final key in keys) {
        final value = summary[key];
        if (value is num) return value.toInt();
        if (value is List) return value.length;
      }
      return 0;
    }

    return InventoryImportPreviewModel(
      importId: ((source['import_id'] ?? source['id']) as num?)?.toInt(),
      totalCount: count(['total', 'total_rows', 'rows_count']),
      newCount: count(['new', 'new_count', 'created']),
      updatedCount: count(['updated', 'updated_count', 'matched']),
      errorCount: count(['errors', 'error_count', 'invalid']),
    );
  }

  InventoryImportPreview toEntity(int importId) => InventoryImportPreview(
        importId: importId,
        totalCount: totalCount,
        newCount: newCount,
        updatedCount: updatedCount,
        errorCount: errorCount,
      );
}
