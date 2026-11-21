/// A medicine the assistant resolved from the patient's message.
class AssistantMedicine {
  final int? id;
  final String name;
  final String? imageUrl;

  const AssistantMedicine({this.id, required this.name, this.imageUrl});
}

/// A pharmacy the assistant suggests for that medicine.
class AssistantPharmacy {
  final int? id;
  final String name;
  final double? distanceKm;
  final double? price;
  final String? phone;

  const AssistantPharmacy({
    this.id,
    required this.name,
    this.distanceKm,
    this.price,
    this.phone,
  });
}

/// The answer to one message (`POST /patient/assistant/chat`).
class AssistantReply {
  /// What the assistant says. May be empty if the API sent only data.
  final String text;
  final List<AssistantMedicine> medicines;
  final List<AssistantPharmacy> pharmacies;

  /// False when the assistant didn't understand the message (`success: false`,
  /// e.g. a greeting that names no medicine).
  final bool understood;

  const AssistantReply({
    required this.text,
    this.medicines = const [],
    this.pharmacies = const [],
    this.understood = true,
  });

  bool get hasResults => medicines.isNotEmpty || pharmacies.isNotEmpty;
}
