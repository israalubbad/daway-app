import '../../domain/entities/medicine_pharmacy_offer.dart';
import '../../../../core/helpers/json_parsing.dart';

class MedicinePharmacyOfferModel {
  final int pharmacyId;
  final String pharmacyName;
  final double? distanceKm;
  final double price;
  final int? pharmacyMedicineId;

  const MedicinePharmacyOfferModel({
    required this.pharmacyId,
    required this.pharmacyName,
    this.distanceKm,
    required this.price,
    this.pharmacyMedicineId,
  });

  factory MedicinePharmacyOfferModel.fromJson(Map<String, dynamic> json) {
    return MedicinePharmacyOfferModel(
      pharmacyId: jsonInt(json['pharmacy_id']) ?? 0,
      pharmacyName: jsonString(json['name']) ?? '',
      distanceKm: jsonDouble(json['distance_km']),
      price: jsonDouble(json['price']) ?? 0,
      pharmacyMedicineId: jsonInt(json['pharmacy_medicine_id']),
    );
  }

  MedicinePharmacyOffer toEntity() => MedicinePharmacyOffer(
        pharmacyId: pharmacyId,
        pharmacyName: pharmacyName,
        distanceKm: distanceKm,
        price: price,
        pharmacyMedicineId: pharmacyMedicineId,
      );
}
