import '../../domain/entities/medicine_detail.dart';
import '../../../../core/helpers/json_reader.dart';

class MedicineDetailModel {
  final int id;
  final String tradeName;
  final String? imageUrl;

  const MedicineDetailModel({
    required this.id,
    required this.tradeName,
    this.imageUrl,
  });

  factory MedicineDetailModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return MedicineDetailModel(
      id: jsonInt(data['id']) ?? 0,
      tradeName: jsonString(data['trade_name']) ?? '',
      imageUrl: jsonString(data['image_url']),
    );
  }

  MedicineDetail toEntity() => MedicineDetail(
        id: id,
        tradeName: tradeName,
        imageUrl: imageUrl,
      );
}
