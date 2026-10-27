import 'package:daway_app/features/pharmacy/data/models/inventory_import_preview_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads the id and the four counts from data', () {
    final model = InventoryImportPreviewModel.fromJson({
      'data': {'import_id': 7, 'total': 128, 'new': 24, 'updated': 104, 'errors': 0},
    });

    expect(model.importId, 7);
    expect(model.totalCount, 128);
    expect(model.newCount, 24);
    expect(model.updatedCount, 104);
    expect(model.errorCount, 0);
  });

  test('counts a list of errors by its length', () {
    final model = InventoryImportPreviewModel.fromJson({
      'data': {
        'id': 3,
        'errors': [
          {'row': 2},
          {'row': 5},
        ],
      },
    });

    expect(model.importId, 3);
    expect(model.errorCount, 2);
  });

  test('a response without an id has none, and missing counts are 0', () {
    final model = InventoryImportPreviewModel.fromJson({'data': <String, dynamic>{}});

    expect(model.importId, isNull);
    expect(model.totalCount, 0);
  });
}
