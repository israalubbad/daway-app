import '../../domain/entities/patient_health_profile.dart';
import '../../../../core/helpers/json_parsing.dart';

class PatientHealthProfileModel {
  final List<String> allergies;
  final List<String> chronicDiseases;
  final String? bloodType;
  final String notes;

  const PatientHealthProfileModel({
    required this.allergies,
    required this.chronicDiseases,
    this.bloodType,
    required this.notes,
  });

  static List<String> _strings(Object? value) =>
      value is List ? [for (final item in value) if (item != null) item.toString()] : const [];

  factory PatientHealthProfileModel.fromJson(Map<String, dynamic> json) {
    final bloodType = jsonString(json['blood_type']);
    return PatientHealthProfileModel(
      allergies: _strings(json['allergies']),
      chronicDiseases: _strings(json['chronic_diseases']),
      bloodType: (bloodType == null || bloodType.isEmpty) ? null : bloodType,
      notes: jsonString(json['notes']) ?? '',
    );
  }

  PatientHealthProfile toEntity() => PatientHealthProfile(
        allergies: allergies,
        chronicDiseases: chronicDiseases,
        bloodType: bloodType,
        notes: notes,
      );
}
