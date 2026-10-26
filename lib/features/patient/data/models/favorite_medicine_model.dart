import '../../domain/entities/favorite_medicine.dart';
import '../../../../core/helpers/json_reader.dart';

class FavoriteMedicineModel {
  final int medicineId;
  final String tradeName;
  final String? tradeNameAr;
  final String? imageUrl;
  final bool isAvailable;
  final int pharmaciesCount;
  final double? minPrice;

  const FavoriteMedicineModel({
    required this.medicineId,
    required this.tradeName,
    this.tradeNameAr,
    this.imageUrl,
    required this.isAvailable,
    required this.pharmaciesCount,
    this.minPrice,
  });

  factory FavoriteMedicineModel.fromJson(Map<String, dynamic> json) {
    return FavoriteMedicineModel(
      medicineId: jsonInt(json['medicine_id']) ?? 0,
      tradeName: jsonString(json['trade_name']) ?? '',
      tradeNameAr: jsonString(json['trade_name_ar']),
      imageUrl: jsonString(json['image_url']),
      // Seen as both a JSON boolean and a 0/1 integer across endpoints.
      isAvailable: json['is_available'] == true || json['is_available'] == 1,
      pharmaciesCount: jsonInt(json['pharmacies_count']) ?? 0,
      minPrice: jsonDouble(json['min_price']),
    );
  }

  FavoriteMedicine toEntity() => FavoriteMedicine(
        medicineId: medicineId,
        tradeName: tradeName,
        tradeNameAr: tradeNameAr,
        imageUrl: imageUrl,
        isAvailable: isAvailable,
        pharmaciesCount: pharmaciesCount,
        minPrice: minPrice,
      );
}
