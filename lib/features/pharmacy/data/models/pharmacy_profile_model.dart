import '../../domain/entities/pharmacy_profile.dart';
import '../../domain/entities/working_hours_entry.dart';
import '../../../../core/helpers/json_reader.dart';

class PharmacyProfileModel {
  final String pharmacyId;
  final String name;
  final String phone;
  final String? logoUrl;
  final double? latitude;
  final double? longitude;
  final String? address;
  final List<WorkingHoursEntry> workingHours;

  const PharmacyProfileModel({
    required this.pharmacyId,
    required this.name,
    required this.phone,
    this.logoUrl,
    this.latitude,
    this.longitude,
    this.address,
    this.workingHours = const [],
  });

  factory PharmacyProfileModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final workingHoursJson = jsonMap(data['working_hours']) ?? const {};

    return PharmacyProfileModel(
      pharmacyId: jsonString(data['pharmacy_id']) ?? '',
      name: jsonString(data['name']) ?? '',
      phone: jsonString(data['phone']) ?? '',
      logoUrl: jsonString(data['logo_url']),
      latitude: jsonDouble(data['latitude']),
      longitude: jsonDouble(data['longitude']),
      address: jsonString(data['address']),
      workingHours: WeekDay.values.map((day) {
        final dayJson = workingHoursJson[day.name] as Map<String, dynamic>?;
        return WorkingHoursEntry(
          day: day,
          open: jsonString(dayJson?['open']),
          close: jsonString(dayJson?['close']),
        );
      }).toList(),
    );
  }

  PharmacyProfile toEntity() => PharmacyProfile(
        pharmacyId: pharmacyId,
        name: name,
        phone: phone,
        logoUrl: logoUrl,
        latitude: latitude,
        longitude: longitude,
        address: address,
        workingHours: workingHours,
      );
}
