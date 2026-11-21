import 'package:flutter/material.dart';

import '../../../../core/routing/routes.dart';

/// Opens the stock-import screen, and answers whether it updated the stock (it
/// pops with `true` then), so the caller can refresh what shows the stock.
Future<bool> openStockImport(BuildContext context) async {
  final updated = await Navigator.of(context).pushNamed(Routes.pharmacyStockImportScreen);
  return updated == true;
}
