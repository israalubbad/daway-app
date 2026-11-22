import '../../domain/entities/patient_address.dart';
import '../../../../core/helpers/json_parsing.dart';

class PatientAddressModel {
  final int id;
  final String label;
  final String recipientName;
  final String phone;
  final String address;
  final double latitude;
  final double longitude;
  final bool isDefault;

  const PatientAddressModel({
    required this.id,
    required this.label,
    required this.recipientName,
    required this.phone,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.isDefault,
  });

  factory PatientAddressModel.fromJson(Map<String, dynamic> json) {
    return PatientAddressModel(
      id: jsonInt(json['id']) ?? 0,
      label: jsonString(json['label']) ?? '',
      recipientName: jsonString(json['recipient_name']) ?? '',
      phone: jsonString(json['phone']) ?? '',
      address: jsonString(json['address']) ?? '',
      latitude: jsonDouble(json['latitude']) ?? 0,
      longitude: jsonDouble(json['longitude']) ?? 0,
      isDefault: jsonBool(json['is_default']) ?? false,
    );
  }

  PatientAddress toEntity() => PatientAddress(
        id: id,
        label: label,
        recipientName: recipientName,
        phone: phone,
        address: address,
        latitude: latitude,
        longitude: longitude,
        isDefault: isDefault,
      );
}
