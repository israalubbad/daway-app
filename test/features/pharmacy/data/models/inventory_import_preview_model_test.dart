import 'package:daway_app/features/pharmacy/data/models/inventory_import_preview_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads a live preview response', () {
    // Shape confirmed against a live POST /pharmacy/inventory/import.
    final model = InventoryImportPreviewModel.fromJson({
      'success': true,
      'message': 'ملخّص المعاينة',
      'data': {
        'uuid': 'eb302757-7012-43c1-850b-3512d5f718d9',
        'status': 'previewed',
        'can_commit': true,
        'summary': {
          'total': 12,
          'matched': 12,
          'review': 0,
          'unmatched': 0,
          'duplicate': 0,
          'error': 0,
        },
        'decisions': {'pending': 0, 'to_link': 12, 'to_create': 0, 'to_skip': 0, 'ready': true},
      },
    });

    expect(model.importId, 'eb302757-7012-43c1-850b-3512d5f718d9');
    expect(model.totalCount, 12);
    expect(model.matchedCount, 12);
    expect(model.unmatchedCount, 0);
    expect(model.errorCount, 0);
    expect(model.canCommit, isTrue);
  });

  test('rows to review count as new, duplicates as errors', () {
    final model = InventoryImportPreviewModel.fromJson({
      'data': {
        'uuid': 'u-1',
        'can_commit': false,
        'summary': {'total': 10, 'matched': 4, 'review': 2, 'unmatched': 1, 'duplicate': 2, 'error': 1},
      },
    });

    expect(model.unmatchedCount, 3);
    expect(model.errorCount, 3);
    expect(model.canCommit, isFalse);
  });

  test('a response without a uuid has no id, and missing counts are 0', () {
    final model = InventoryImportPreviewModel.fromJson({'data': <String, dynamic>{}});

    expect(model.importId, isNull);
    expect(model.totalCount, 0);
  });
}
