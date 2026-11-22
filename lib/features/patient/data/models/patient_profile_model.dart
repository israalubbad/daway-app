import '../../domain/entities/patient_profile.dart';
import '../../../../core/helpers/json_parsing.dart';

class PatientProfileModel {
  final String name;
  final String phone;
  final String? avatarUrl;
  final String? birthDate;
  final double? latitude;
  final double? longitude;
  final String? address;

  const PatientProfileModel({
    required this.name,
    required this.phone,
    this.avatarUrl,
    this.birthDate,
    this.latitude,
    this.longitude,
    this.address,
  });

  factory PatientProfileModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return PatientProfileModel(
      name: jsonString(data['name']) ?? '',
      phone: jsonString(data['phone']) ?? '',
      avatarUrl: jsonString(data['avatar_url']),
      birthDate: jsonString(data['birth_date']),
      latitude: jsonDouble(data['latitude']),
      longitude: jsonDouble(data['longitude']),
      address: jsonString(data['address']),
    );
  }

  PatientProfile toEntity() => PatientProfile(
        name: name,
        phone: phone,
        avatarUrl: avatarUrl,
        birthDate: birthDate,
        latitude: latitude,
        longitude: longitude,
        address: address,
      );
}
