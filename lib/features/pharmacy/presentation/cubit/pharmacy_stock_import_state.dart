import '../../domain/entities/inventory_import_preview.dart';

/// The spreadsheet the pharmacy picked.
class PickedStockFile {
  final String path;
  final String name;
  final int sizeBytes;

  const PickedStockFile({required this.path, required this.name, required this.sizeBytes});
}

/// The stock-file import is a short flow: pick a file, analyse it, then
/// confirm. Every state carries the picked [file] (null before one is picked).
sealed class PharmacyStockImportState {
  final PickedStockFile? file;

  const PharmacyStockImportState(this.file);
}

/// No file yet, or one picked and waiting to be analysed. [message] is the last
/// failure, if any.
class StockImportIdle extends PharmacyStockImportState {
  final String? message;

  const StockImportIdle(super.file, {this.message});
}

class StockImportAnalyzing extends PharmacyStockImportState {
  const StockImportAnalyzing(super.file);
}

/// The backend analysed the file; [updateError] is why the last attempt to
/// confirm it failed, if it did.
class StockImportAnalyzed extends PharmacyStockImportState {
  final InventoryImportPreview preview;
  final String? updateError;

  const StockImportAnalyzed(super.file, this.preview, {this.updateError});
}

class StockImportUpdating extends PharmacyStockImportState {
  final InventoryImportPreview preview;

  const StockImportUpdating(super.file, this.preview);
}

class StockImportUpdated extends PharmacyStockImportState {
  final InventoryImportPreview preview;

  const StockImportUpdated(super.file, this.preview);
}
