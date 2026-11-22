import '../../domain/entities/category_medicine.dart';
import '../../../../core/helpers/json_parsing.dart';

class CategoryMedicineModel {
  final int id;
  final String tradeName;
  final String? genericName;
  final String? dosageForm;
  final int? medicineId;
  final String? imageUrl;
  final int? pharmaciesCount;

  const CategoryMedicineModel({
    required this.id,
    required this.tradeName,
    this.genericName,
    this.dosageForm,
    this.medicineId,
    this.imageUrl,
    this.pharmaciesCount,
  });

  factory CategoryMedicineModel.fromJson(Map<String, dynamic> json) {
    return CategoryMedicineModel(
      id: jsonInt(json['id']) ?? (throw const FormatException('Record has no id')),
      tradeName: jsonString(json['trade_name']) ?? '',
      genericName: jsonString(json['generic_name']),
      dosageForm: jsonString(json['dosage_form']),
      medicineId: jsonInt(json['medicine_id']),
      imageUrl: jsonString(json['image_url']) ?? jsonString(json['image']),
      pharmaciesCount: jsonInt(json['pharmacies_count']),
    );
  }

  CategoryMedicine toEntity() => CategoryMedicine(
        id: id,
        tradeName: tradeName,
        genericName: genericName,
        dosageForm: dosageForm,
        medicineId: medicineId,
        imageUrl: imageUrl,
        pharmaciesCount: pharmaciesCount,
      );
}
