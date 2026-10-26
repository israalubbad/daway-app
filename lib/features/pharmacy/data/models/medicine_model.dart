import '../../domain/entities/medicine.dart';
import '../../../../core/helpers/json_reader.dart';

/// Parses a `pharmacy_medicine` record. The descriptive fields (trade name,
/// active ingredient, image) live on the nested `medicine` catalog object,
/// confirmed against a live `GET /pharmacy/medicines` response.
class MedicineModel {
  final int id;
  final int medicineId;
  final String name;
  final String? nameAr;
  final String? activeIngredient;
  final String? imageUrl;
  final double price;
  final int quantity;
  final bool isAvailable;
  final bool? isLowStock;
  final bool? isOutOfStock;

  const MedicineModel({
    required this.id,
    required this.medicineId,
    required this.name,
    this.nameAr,
    this.activeIngredient,
    this.imageUrl,
    required this.price,
    required this.quantity,
    required this.isAvailable,
    this.isLowStock,
    this.isOutOfStock,
  });

  factory MedicineModel.fromJson(Map<String, dynamic> json) {
    final catalog = jsonMap(json['medicine']) ?? const {};

    return MedicineModel(
      id: jsonInt(json['id']) ?? 0,
      medicineId: jsonInt(json['medicine_id']) ?? jsonInt(catalog['id']) ?? 0,
      name: jsonString(catalog['trade_name']) ?? '',
      nameAr: jsonString(catalog['trade_name_ar']),
      activeIngredient: jsonString(catalog['active_ingredient']),
      imageUrl: jsonString(catalog['image_url']),
      price: _parseDouble(json['price']),
      quantity: jsonInt(json['quantity']) ?? 0,
      isAvailable: jsonBool(json['is_available']) ?? true,
      isLowStock: jsonBool(json['is_low_stock']),
      isOutOfStock: jsonBool(json['is_out_of_stock']),
    );
  }

  static double _parseDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  Medicine toEntity() => Medicine(
        id: id,
        medicineId: medicineId,
        name: name,
        nameAr: nameAr,
        activeIngredient: activeIngredient,
        imageUrl: imageUrl,
        price: price,
        quantity: quantity,
        isAvailable: isAvailable,
        isLowStock: isLowStock,
        isOutOfStock: isOutOfStock,
      );
}
