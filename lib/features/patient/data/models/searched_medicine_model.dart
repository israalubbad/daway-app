import '../../domain/entities/searched_medicine.dart';
import '../../../../core/helpers/json_parsing.dart';

class SearchedMedicineModel {
  final int id;
  final String tradeName;
  final String? activeIngredient;
  final String? imageUrl;
  final bool isAvailable;
  final int availablePharmaciesCount;

  const SearchedMedicineModel({
    required this.id,
    required this.tradeName,
    this.activeIngredient,
    this.imageUrl,
    required this.isAvailable,
    required this.availablePharmaciesCount,
  });

  factory SearchedMedicineModel.fromJson(Map<String, dynamic> json) {
    return SearchedMedicineModel(
      id: jsonInt(json['id']) ?? (throw const FormatException('Record has no id')),
      tradeName: jsonString(json['trade_name']) ?? '',
      activeIngredient: jsonString(json['active_ingredient']),
      imageUrl: jsonString(json['image_url']),
      // The live API serializes this as an int (0/1), not a JSON boolean.
      isAvailable: json['is_available'] == true || json['is_available'] == 1,
      availablePharmaciesCount:
          jsonInt(json['available_pharmacies_count']) ?? 0,
    );
  }

  SearchedMedicine toEntity() => SearchedMedicine(
        id: id,
        tradeName: tradeName,
        activeIngredient: activeIngredient,
        imageUrl: imageUrl,
        isAvailable: isAvailable,
        availablePharmaciesCount: availablePharmaciesCount,
      );
}
