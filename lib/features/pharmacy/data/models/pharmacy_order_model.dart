import '../../../../core/helpers/json_parsing.dart';
import '../../../../core/helpers/server_timestamp.dart';
import '../../domain/entities/pharmacy_order.dart';

/// One record of `GET /pharmacy/sub-orders`.
///
/// The response shape has not been seen (no sample, no test account), so the
/// parser reads each field from the names such an API most likely uses — on
/// the record itself or on a nested `order` — and only the id is required.
/// Replace the guesses with the real names once a sample exists.
class PharmacyOrderModel {
  final PharmacyOrder order;

  const PharmacyOrderModel(this.order);

  factory PharmacyOrderModel.fromJson(Map<String, dynamic> json) {
    final parent = jsonMap(json['order']);
    final id = jsonInt(json['id']);
    if (id == null) throw FormatException('Sub-order without an id: $json');

    final rawItems = json['items'] ?? json['order_items'] ?? json['lines'];
    final items = <PharmacyOrderItem>[
      if (rawItems is List)
        for (final raw in rawItems)
          if (raw is Map<String, dynamic>) _item(raw),
    ];

    final address = jsonMap(json['address']) ??
        jsonMap(json['delivery_address']) ??
        jsonMap(parent?['address']) ??
        jsonMap(parent?['delivery_address']);
    final area = jsonString(address?['area']) ??
        jsonString(address?['city']) ??
        jsonString(address?['label']) ??
        jsonString(json['area']) ??
        '';
    final street = jsonString(address?['street']) ??
        jsonString(address?['address']) ??
        jsonString(address?['details']);

    // The server's clock is UTC even when the stamp carries no zone, which
    // tryParseServerTimestamp knows; a missing stamp reads as "now".
    final createdAt = tryParseServerTimestamp(
          jsonString(json['created_at']) ?? jsonString(parent?['created_at']),
        ) ??
        DateTime.now();

    final total = jsonDouble(json['total']) ??
        jsonDouble(json['total_amount']) ??
        jsonDouble(json['subtotal']) ??
        items.fold<double>(0, (sum, item) => sum + item.price);

    return PharmacyOrderModel(
      PharmacyOrder(
        id: id,
        status: _status(jsonString(json['status'])),
        orderNumber: jsonString(json['order_number']) ??
            jsonString(parent?['order_number']) ??
            jsonString(json['number']) ??
            '$id',
        createdAt: createdAt,
        // A list response often carries only the count, not the lines.
        itemsCount: items.isNotEmpty ? items.length : (jsonInt(json['items_count']) ?? 0),
        total: total,
        area: area,
        items: items,
        deliveryStreet: street,
        payment: _payment(json, parent),
        patientName: _patientName(json, parent),
      ),
    );
  }

  static PharmacyOrderItem _item(Map<String, dynamic> raw) {
    final medicine = jsonMap(raw['medicine']) ?? jsonMap(raw['pharmacy_medicine']);
    final quantity = jsonInt(raw['quantity']) ?? 1;
    final unit = jsonDouble(raw['unit_price']) ?? jsonDouble(raw['price']) ?? 0;
    return PharmacyOrderItem(
      // `medicine_trade_name`, `quantity`, `unit_price` and `total_price` are
      // the documented names (Postman collection); the rest are fallbacks.
      name: jsonString(raw['medicine_trade_name']) ??
          jsonString(raw['name']) ??
          jsonString(raw['medicine_name']) ??
          jsonString(medicine?['name']) ??
          jsonString(medicine?['trade_name']) ??
          '',
      price: jsonDouble(raw['total_price']) ?? jsonDouble(raw['total']) ?? unit * quantity,
      imageUrl: jsonString(raw['image_url']) ?? jsonString(medicine?['image_url']),
      quantity: quantity,
      unitPrice: raw.containsKey('unit_price') || raw.containsKey('price') ? unit : null,
    );
  }

  /// The patient's name — on the record or the parent order, as a plain
  /// string or inside a `patient` / `customer` / `user` object.
  static String? _patientName(Map<String, dynamic> json, Map<String, dynamic>? parent) {
    for (final source in [json, parent]) {
      if (source == null) continue;
      final direct = jsonString(source['patient_name']) ?? jsonString(source['customer_name']);
      if (direct != null) return direct;
      for (final key in ['patient', 'customer', 'user']) {
        final nested = jsonMap(source[key]);
        final name = jsonString(nested?['name']) ?? jsonString(nested?['full_name']);
        if (name != null) return name;
      }
    }
    return null;
  }

  static PharmacyOrderPayment? _payment(
    Map<String, dynamic> json,
    Map<String, dynamic>? parent,
  ) {
    final raw = jsonMap(json['payment']) ?? jsonMap(parent?['payment']);
    final method = jsonString(raw?['method']) ??
        jsonString(raw?['payment_method']) ??
        jsonString(json['payment_method']) ??
        jsonString(parent?['payment_method']);
    if (method == null) return null;
    final paid = raw?['status'] == 'paid' ||
        raw?['is_paid'] == true ||
        json['payment_status'] == 'paid' ||
        parent?['payment_status'] == 'paid';
    return PharmacyOrderPayment(method: method, isPaid: paid);
  }

  static PharmacyOrderStatus _status(String? raw) {
    final status = raw?.toLowerCase();
    if (status == null) return PharmacyOrderStatus.pending;
    bool has(List<String> words) => words.any(status.contains);
    // Checked first: "pending_confirmation" is waiting, not confirmed.
    if (has(['pending', 'await', 'new', 'wait'])) return PharmacyOrderStatus.pending;
    if (has(['reject', 'declin', 'cancel', 'refus'])) return PharmacyOrderStatus.rejected;
    if (has(['accept', 'confirm', 'approv', 'prepar', 'ready', 'deliver', 'complet'])) {
      return PharmacyOrderStatus.accepted;
    }
    return PharmacyOrderStatus.other;
  }

}
