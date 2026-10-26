import '../../domain/entities/nearby_pharmacy.dart';
import '../../../../core/helpers/json_reader.dart';

class NearbyPharmacyModel {
  final int id;
  final String name;
  final String? address;
  final double latitude;
  final double longitude;
  final String? phoneNumber;
  final bool isOpenNow;

  const NearbyPharmacyModel({
    required this.id,
    required this.name,
    this.address,
    required this.latitude,
    required this.longitude,
    this.phoneNumber,
    required this.isOpenNow,
  });

  factory NearbyPharmacyModel.fromJson(Map<String, dynamic> json) {
    return NearbyPharmacyModel(
      id: jsonInt(json['id']) ?? 0,
      name: jsonString(json['pharmacy_name']) ?? '',
      address: jsonString(json['address']),
      latitude: jsonDouble(json['latitude']) ?? 0,
      longitude: jsonDouble(json['longitude']) ?? 0,
      phoneNumber: jsonString(json['phone_number']),
      // Seen as both a JSON boolean and a 0/1 integer across this backend's
      // endpoints (see FavoriteMedicineModel's is_available parsing).
      isOpenNow: json['is_open_now'] == true || json['is_open_now'] == 1,
    );
  }

  NearbyPharmacy toEntity() => NearbyPharmacy(
        id: id,
        name: name,
        address: address,
        latitude: latitude,
        longitude: longitude,
        phoneNumber: phoneNumber,
        isOpenNow: isOpenNow,
      );
}
