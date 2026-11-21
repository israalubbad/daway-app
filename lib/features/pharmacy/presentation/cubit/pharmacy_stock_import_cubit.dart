import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/helpers/api_result.dart';
import '../../domain/usecases/analyze_inventory_import_usecase.dart';
import '../../domain/usecases/cancel_inventory_import_usecase.dart';
import '../../domain/usecases/commit_inventory_import_usecase.dart';
import '../../domain/usecases/download_inventory_import_template_usecase.dart';
import '../../domain/usecases/export_current_inventory_usecase.dart';
import 'pharmacy_stock_import_state.dart';

class PharmacyStockImportCubit extends Cubit<PharmacyStockImportState> {
  final AnalyzeInventoryImportUseCase _analyzeUseCase;
  final CommitInventoryImportUseCase _commitUseCase;
  final CancelInventoryImportUseCase _cancelUseCase;

  final DownloadInventoryImportTemplateUseCase _downloadTemplateUseCase;
  final ExportCurrentInventoryUseCase _exportCurrentUseCase;

  PharmacyStockImportCubit(
    this._analyzeUseCase,
    this._commitUseCase,
    this._cancelUseCase,
    this._downloadTemplateUseCase,
    this._exportCurrentUseCase,
  ) : super(const StockImportIdle(null));

  /// The template's bytes, for the screen to hand to the system's save dialog.
  Future<ApiResult<Uint8List>> downloadTemplate() => _downloadTemplateUseCase();

  /// The pharmacy's current stock as a spreadsheet, for the same save dialog.
  Future<ApiResult<Uint8List>> exportCurrentInventory() => _exportCurrentUseCase();

  /// Picking (or replacing) a file. An analysis the previous file already has
  /// is dropped on the backend, best effort.
  void fileSelected(PickedStockFile file) {
    _cancelPendingImport();
    emit(StockImportIdle(file));
  }

  Future<void> analyze() async {
    final file = state.file;
    if (file == null || state is StockImportAnalyzing) return;

    emit(StockImportAnalyzing(file));

    final result = await _analyzeUseCase(file.path);

    switch (result) {
      case Success(:final data):
        emit(StockImportAnalyzed(file, data));
      case ApiError(:final failure):
        emit(StockImportIdle(file, message: failure.message));
    }
  }

  Future<void> update() async {
    final current = state;
    if (current is! StockImportAnalyzed) return;

    emit(StockImportUpdating(current.file, current.preview));

    final result = await _commitUseCase(current.preview.importId);

    switch (result) {
      case Success():
        emit(StockImportUpdated(current.file, current.preview));
      case ApiError(:final failure):
        emit(StockImportAnalyzed(current.file, current.preview, updateError: failure.message));
    }
  }

  @override
  Future<void> close() {
    _cancelPendingImport();
    return super.close();
  }

  void _cancelPendingImport() {
    if (state case StockImportAnalyzed(:final preview)) {
      _cancelUseCase(preview.importId);
    }
  }
}
