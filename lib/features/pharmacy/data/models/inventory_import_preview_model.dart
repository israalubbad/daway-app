import '../../domain/entities/inventory_import_preview.dart';

/// Parsed from the response of `POST /pharmacy/inventory/import`. The
/// collection documents no response for it, so the field names are a best
/// guess that has not been checked against a live pharmacy login: the id and
/// each count are looked for under several likely names, at any depth, and
/// every count falls back to 0. A response with no id is rejected by the
/// repository.
class InventoryImportPreviewModel {
  static const _idKeys = ['import_id', 'inventory_import_id', 'batch_id', 'id'];
  static const _totalKeys = [
    'total',
    'total_rows',
    'rows_count',
    'rows',
    'total_count',
    'products_count',
    'count',
  ];
  static const _newKeys = ['new', 'new_count', 'new_products', 'to_create', 'created', 'creates'];
  static const _updatedKeys = [
    'updated',
    'updated_count',
    'updates',
    'to_update',
    'matched',
    'existing',
  ];
  static const _errorKeys = ['errors', 'error_count', 'invalid', 'invalid_rows', 'failed'];

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
    final newCount = _count(json, _newKeys);
    final updatedCount = _count(json, _updatedKeys);
    final errorCount = _count(json, _errorKeys);
    final total = _count(json, _totalKeys);

    return InventoryImportPreviewModel(
      importId: _find(json, _idKeys, (value) {
        if (value is num) return value.toInt();
        if (value is String) return int.tryParse(value);
        return null;
      }),
      totalCount: total > 0 ? total : newCount + updatedCount + errorCount,
      newCount: newCount,
      updatedCount: updatedCount,
      errorCount: errorCount,
    );
  }

  /// The first value under any of [keys] (in that order of preference) that
  /// [read] accepts, looking through nested maps breadth-first.
  static T? _find<T>(Map<String, dynamic> root, List<String> keys, T? Function(Object?) read) {
    final queue = <Map<String, dynamic>>[root];
    final levels = <Map<String, dynamic>>[];
    while (queue.isNotEmpty) {
      final map = queue.removeAt(0);
      levels.add(map);
      for (final value in map.values) {
        if (value is Map<String, dynamic>) queue.add(value);
      }
    }
    for (final map in levels) {
      for (final key in keys) {
        final found = read(map[key]);
        if (found != null) return found;
      }
    }
    return null;
  }

  /// A number, or the length of a list, under any of [keys].
  static int _count(Map<String, dynamic> root, List<String> keys) {
    return _find<int>(root, keys, (value) {
          if (value is num) return value.toInt();
          if (value is List) return value.length;
          return null;
        }) ??
        0;
  }

  InventoryImportPreview toEntity(int importId) => InventoryImportPreview(
        importId: importId,
        totalCount: totalCount,
        newCount: newCount,
        updatedCount: updatedCount,
        errorCount: errorCount,
      );
}
