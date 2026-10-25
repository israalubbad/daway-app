import '../../domain/entities/assistant_reply.dart';

/// Reads the assistant's response. The response's exact shape is not
/// documented (the collection has no saved example), so this accepts the
/// field names the rest of the API uses and never throws on a missing one:
/// whatever is not recognised is simply left out, and the assistant's text
/// still shows.
class AssistantReplyModel {
  static const _maxResults = 5;

  static AssistantReply fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final dataMap = data is Map<String, dynamic> ? data : const <String, dynamic>{};

    return AssistantReply(
      text: _firstText([
        json['reply'],
        json['answer'],
        dataMap['reply'],
        dataMap['answer'],
        dataMap['message'],
        json['message'],
      ]),
      medicines: _medicines(dataMap, json),
      pharmacies: _pharmacies(dataMap, json),
      understood: json['success'] != false,
    );
  }

  static String _firstText(List<Object?> candidates) {
    for (final candidate in candidates) {
      if (candidate is String && candidate.trim().isNotEmpty) return candidate.trim();
    }
    return '';
  }

  static List<Map<String, dynamic>> _maps(Object? value) {
    if (value is Map<String, dynamic>) return [value];
    if (value is List) return [for (final item in value) if (item is Map<String, dynamic>) item];
    return const [];
  }

  static List<AssistantMedicine> _medicines(
    Map<String, dynamic> data,
    Map<String, dynamic> root,
  ) {
    final rows = [
      ..._maps(data['medicines']),
      ..._maps(data['medicine']),
      ..._maps(data['resolved_medicine']),
      ..._maps(data['results']),
      ..._maps(root['medicines']),
      ..._maps(root['medicine']),
    ];
    return [
      for (final row in rows.take(_maxResults))
        if (_name(row, const ['trade_name', 'name', 'medicine_name']) case final name?)
          AssistantMedicine(
            id: _int(row['medicine_id'] ?? row['id']),
            name: name,
            imageUrl: _string(row['image_url'] ?? row['image']),
          ),
    ];
  }

  static List<AssistantPharmacy> _pharmacies(
    Map<String, dynamic> data,
    Map<String, dynamic> root,
  ) {
    final rows = [
      ..._maps(data['pharmacies']),
      ..._maps(data['nearest_pharmacies']),
      ..._maps(root['pharmacies']),
    ];
    return [
      for (final row in rows.take(_maxResults))
        if (_name(row, const ['name', 'pharmacy_name']) case final name?)
          AssistantPharmacy(
            id: _int(row['pharmacy_id'] ?? row['id']),
            name: name,
            distanceKm: _double(row['distance_km']),
            price: _double(row['price']),
            phone: _string(row['phone'] ?? row['phone_number']),
          ),
    ];
  }

  static String? _name(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  static String? _string(Object? value) => value is String && value.isNotEmpty ? value : null;

  static int? _int(Object? value) => value is num ? value.toInt() : int.tryParse('$value');

  static double? _double(Object? value) =>
      value is num ? value.toDouble() : double.tryParse('$value');
}
