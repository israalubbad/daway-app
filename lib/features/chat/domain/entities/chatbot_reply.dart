import '../../../../core/localization/translations.dart';

/// A medicine the assistant found (`medicine` / one of `alternatives`).
class ChatbotMedicine {
  final int id;
  final String name;
  final String? nameAr;
  final String? activeIngredient;
  final String? imageUrl;

  /// `is_available` of an alternative, when the server says it.
  final bool? isAvailable;

  const ChatbotMedicine({
    required this.id,
    required this.name,
    this.nameAr,
    this.activeIngredient,
    this.imageUrl,
    this.isAvailable,
  });
}

/// One pharmacy that has the medicine (a row of `pharmacies`).
class ChatbotPharmacy {
  final int pharmacyId;
  final String name;
  final double? price;
  final int? quantity;

  /// The server's availability word (`available`, ...), shown as it is
  /// understood by [ChatbotPharmacy.availabilityLabel].
  final String? availability;
  final double? distanceKm;
  final bool? isOpenNow;
  final String? address;

  const ChatbotPharmacy({
    required this.pharmacyId,
    required this.name,
    this.price,
    this.quantity,
    this.availability,
    this.distanceKm,
    this.isOpenNow,
    this.address,
  });

  /// Arabic label of the availability word, or null for one that is not known
  /// (it is then not shown rather than shown raw).
  String? get availabilityLabel => switch (availability) {
        'available' => 'متوفر'.tr,
        'low_stock' || 'low' => 'كمية قليلة'.tr,
        'out_of_stock' || 'unavailable' => 'غير متوفر'.tr,
        _ => null,
      };
}

/// What the assistant answered: its words, and/or the medicine it found with
/// the pharmacies that have it. All of it comes from the API.
class ChatbotReply {
  final String? text;
  final ChatbotMedicine? medicine;
  final List<ChatbotPharmacy> pharmacies;
  final List<ChatbotMedicine> alternatives;
  final int? totalFound;

  const ChatbotReply({
    this.text,
    this.medicine,
    this.pharmacies = const [],
    this.alternatives = const [],
    this.totalFound,
  });

  bool get hasResults => medicine != null || alternatives.isNotEmpty;

  /// True when there is nothing at all to show.
  bool get isEmpty => text == null && !hasResults;
}
