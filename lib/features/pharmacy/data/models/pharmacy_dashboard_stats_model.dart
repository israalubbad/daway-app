import '../../domain/entities/pharmacy_dashboard_stats.dart';
import '../../../../core/helpers/json_reader.dart';

/// Parses `GET /pharmacy/dashboard/stats`. Field names confirmed against a
/// live response — the stats object has no average-rating field, so
/// [PharmacyDashboardRepositoryImpl] derives that separately.
class PharmacyDashboardStatsModel {
  final int totalMedicines;
  final int availableCount;
  final int lowStockCount;
  final int outOfStockCount;
  final int newInquiriesCount;
  final List<PharmacyDashboardLowStockItem> lowStockItems;

  const PharmacyDashboardStatsModel({
    required this.totalMedicines,
    required this.availableCount,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.newInquiriesCount,
    required this.lowStockItems,
  });

  factory PharmacyDashboardStatsModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final lowStockItemsJson = data['low_stock_items'] as List<dynamic>? ?? const [];

    return PharmacyDashboardStatsModel(
      totalMedicines: jsonInt(data['total_medicines']) ?? 0,
      availableCount: jsonInt(data['available_count']) ?? 0,
      lowStockCount: jsonInt(data['low_count']) ?? 0,
      outOfStockCount: jsonInt(data['out_count']) ?? 0,
      newInquiriesCount: jsonInt(data['pending_inquiries']) ?? 0,
      lowStockItems: lowStockItemsJson.map((item) {
        final itemJson = item as Map<String, dynamic>;
        return PharmacyDashboardLowStockItem(
          pharmacyMedicineId: jsonInt(itemJson['pharmacy_medicine_id']) ?? 0,
          tradeName: jsonString(itemJson['trade_name']) ?? '',
          quantity: jsonInt(itemJson['quantity']) ?? 0,
        );
      }).toList(),
    );
  }
}
