import '../../../../core/erroring/error_handler.dart';
import '../../../../core/helpers/api_result.dart';
import '../../domain/entities/chatbot_reply.dart';
import '../../domain/repositories/chatbot_repository.dart';
import '../datasources/chatbot_remote_data_source.dart';

class ChatbotRepositoryImpl implements ChatbotRepository {
  final ChatbotRemoteDataSource _remoteDataSource;

  const ChatbotRepositoryImpl(this._remoteDataSource);

  @override
  Future<ApiResult<ChatbotReply>> send({required String token, required String message}) {
    return guardApi(() async {
      final response = await _remoteDataSource.chat(token: token, message: message);
      return Success(parseReply(response.data));
    });
  }

  /// What the assistant answered, exactly as the API sent it: its words
  /// ([replyText]) and the medicine / pharmacies / alternatives it found.
  static ChatbotReply parseReply(Object? body) {
    if (body is! Map) return ChatbotReply(text: replyText(body));

    final medicine = _medicine(body['medicine']);
    return ChatbotReply(
      text: replyText(body),
      medicine: medicine,
      pharmacies: [
        for (final raw in (body['pharmacies'] as List?) ?? const [])
          if (raw is Map) _pharmacy(raw),
      ],
      alternatives: [
        for (final raw in (body['alternatives'] as List?) ?? const []) ?_medicine(raw),
      ],
      totalFound: (body['total_found'] as num?)?.toInt(),
    );
  }

  static ChatbotMedicine? _medicine(Object? raw) {
    if (raw is! Map) return null;
    final id = (raw['id'] as num?)?.toInt();
    if (id == null) return null;
    return ChatbotMedicine(
      id: id,
      name: _text(raw['name']) ?? _text(raw['trade_name']) ?? '',
      nameAr: _text(raw['trade_name_ar']),
      activeIngredient: _text(raw['active_ingredient']),
      imageUrl: _text(raw['image_url']),
      isAvailable: raw['is_available'] as bool?,
    );
  }

  static ChatbotPharmacy _pharmacy(Map raw) {
    return ChatbotPharmacy(
      pharmacyId: (raw['pharmacy_id'] as num?)?.toInt() ?? (raw['id'] as num?)?.toInt() ?? 0,
      name: _text(raw['name']) ?? '',
      price: (raw['price'] as num?)?.toDouble(),
      quantity: (raw['quantity'] as num?)?.toInt(),
      availability: _text(raw['availability']),
      distanceKm: (raw['distance_km'] as num?)?.toDouble(),
      isOpenNow: raw['is_open_now'] as bool?,
      address: _text(raw['address']),
    );
  }

  /// The assistant's own words from a response body, exactly as the API sent
  /// them; null when the response carries none (the app then shows nothing
  /// rather than inventing a reply).
  ///
  /// The assistant's `reply` sits in the analysis object (`analysis.reply`) or
  /// at the top level; the endpoint's own `message` (for example "could not
  /// identify the medicine") is only used when there is no `reply`. A
  /// `guidance` text, when present, follows the reply.
  static String? replyText(Object? body) {
    if (body is! Map) return _text(body);

    final sources = <Object?>[body['analysis'], body, body['data']];
    final reply = _firstText(sources, const ['reply']) ??
        _firstText(sources, const ['message', 'answer', 'response', 'text']);
    if (reply == null) return null;

    final guidance = _firstText(sources, const ['guidance']);
    return guidance == null || guidance == reply ? reply : '$reply\n\n$guidance';
  }

  static String? _firstText(List<Object?> nodes, List<String> keys) {
    for (final node in nodes) {
      if (node is! Map) continue;
      for (final key in keys) {
        final text = _text(node[key]);
        if (text != null) return text;
      }
    }
    return null;
  }

  static String? _text(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
