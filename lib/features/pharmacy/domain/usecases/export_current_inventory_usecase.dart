import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../../../../core/erroring/failure.dart';
import '../../../../core/helpers/api_result.dart';
import '../entities/medicine.dart';
import 'get_pharmacy_medicines_usecase.dart';

/// Builds the pharmacy's current stock as an .xlsx file, one row per medicine.
/// The backend has no export endpoint, so the list `GET /pharmacy/medicines`
/// returns is written out here.
class ExportCurrentInventoryUseCase {
  /// The header row: the medicine's names, its active ingredient, and its stock.
  static const List<String> headers = [
    'name',
    'name_ar',
    'active_ingredient',
    'price',
    'quantity',
  ];

  final GetPharmacyMedicinesUseCase _getMedicines;

  const ExportCurrentInventoryUseCase(this._getMedicines);

  Future<ApiResult<Uint8List>> call() async {
    final result = await _getMedicines();

    switch (result) {
      case ApiError(:final failure):
        return ApiError(failure);
      case Success(:final data):
        final bytes = _build(data);
        if (bytes == null) {
          return const ApiError(ApiFailure(message: 'تعذر إنشاء ملف المنتجات'));
        }
        return Success(bytes);
    }
  }

  Uint8List? _build(List<Medicine> medicines) {
    final excel = Excel.createExcel();
    final sheetName = excel.getDefaultSheet() ?? 'Sheet1';
    final sheet = excel[sheetName];

    sheet.appendRow([for (final header in headers) TextCellValue(header)]);
    for (final medicine in medicines) {
      sheet.appendRow([
        TextCellValue(medicine.name),
        TextCellValue(medicine.nameAr ?? ''),
        TextCellValue(medicine.activeIngredient ?? ''),
        DoubleCellValue(medicine.price),
        IntCellValue(medicine.quantity),
      ]);
    }

    final encoded = excel.encode();
    return encoded == null ? null : Uint8List.fromList(encoded);
  }
}
