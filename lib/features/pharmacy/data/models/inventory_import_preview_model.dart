import '../../domain/entities/inventory_import_preview.dart';

/// Parsed from `POST /pharmacy/inventory/import`, confirmed against a live
/// response:
/// `data: {uuid, status, can_commit, summary: {total, matched, review,
/// unmatched, duplicate, error}, decisions: {...}}`.
class InventoryImportPreviewModel {
  final String? importId;
  final int totalCount;
  final int matchedCount;
  final int unmatchedCount;
  final int errorCount;
  final bool canCommit;

  const InventoryImportPreviewModel({
    required this.importId,
    required this.totalCount,
    required this.matchedCount,
    required this.unmatchedCount,
    required this.errorCount,
    required this.canCommit,
  });

  factory InventoryImportPreviewModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : json;
    final summary =
        data['summary'] is Map<String, dynamic> ? data['summary'] as Map<String, dynamic> : const {};

    int count(String key) => (summary[key] as num?)?.toInt() ?? 0;

    return InventoryImportPreviewModel(
      importId: data['uuid']?.toString(),
      totalCount: count('total'),
      matchedCount: count('matched'),
      // Rows that need a look ("review") are not matched either.
      unmatchedCount: count('unmatched') + count('review'),
      errorCount: count('error') + count('duplicate'),
      canCommit: data['can_commit'] as bool? ?? true,
    );
  }

  InventoryImportPreview toEntity(String importId) => InventoryImportPreview(
        importId: importId,
        totalCount: totalCount,
        updatedCount: matchedCount,
        newCount: unmatchedCount,
        errorCount: errorCount,
        canCommit: canCommit,
      );
}
