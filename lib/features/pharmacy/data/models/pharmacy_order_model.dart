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
    final parent = _map(json['order']);
    final id = _int(json['id']);
    if (id == null) throw FormatException('Sub-order without an id: $json');

    final rawItems = json['items'] ?? json['order_items'] ?? json['lines'];
    final items = <PharmacyOrderItem>[
      if (rawItems is List)
        for (final raw in rawItems)
          if (raw is Map<String, dynamic>) _item(raw),
    ];

    final address = _map(json['address']) ??
        _map(json['delivery_address']) ??
        _map(parent?['address']) ??
        _map(parent?['delivery_address']);
    final area = _string(address?['area']) ??
        _string(address?['city']) ??
        _string(address?['label']) ??
        _string(json['area']) ??
        '';
    final street = _string(address?['street']) ??
        _string(address?['address']) ??
        _string(address?['details']);

    final createdAt = DateTime.tryParse(
          _string(json['created_at']) ?? _string(parent?['created_at']) ?? '',
        )?.toLocal() ??
        DateTime.now();

    final total = _double(json['total']) ??
        _double(json['total_amount']) ??
        _double(json['subtotal']) ??
        items.fold<double>(0, (sum, item) => sum + item.price);

    return PharmacyOrderModel(
      PharmacyOrder(
        id: id,
        status: _status(_string(json['status'])),
        orderNumber: _string(json['order_number']) ??
            _string(parent?['order_number']) ??
            _string(json['number']) ??
            '$id',
        createdAt: createdAt,
        itemsCount: items.length,
        total: total,
        area: area,
        items: items,
        deliveryStreet: street,
        payment: _payment(json, parent),
      ),
    );
  }

  static PharmacyOrderItem _item(Map<String, dynamic> raw) {
    final medicine = _map(raw['medicine']) ?? _map(raw['pharmacy_medicine']);
    final quantity = _int(raw['quantity']) ?? 1;
    final unit = _double(raw['unit_price']) ?? _double(raw['price']) ?? 0;
    return PharmacyOrderItem(
      name: _string(raw['name']) ??
          _string(raw['medicine_name']) ??
          _string(medicine?['name']) ??
          _string(medicine?['trade_name']) ??
          '',
      price: _double(raw['total']) ?? unit * quantity,
      imageUrl: _string(raw['image_url']) ?? _string(medicine?['image_url']),
    );
  }

  static PharmacyOrderPayment? _payment(
    Map<String, dynamic> json,
    Map<String, dynamic>? parent,
  ) {
    final raw = _map(json['payment']) ?? _map(parent?['payment']);
    final method = _string(raw?['method']) ??
        _string(raw?['payment_method']) ??
        _string(json['payment_method']) ??
        _string(parent?['payment_method']);
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

  static Map<String, dynamic>? _map(Object? value) =>
      value is Map<String, dynamic> ? value : null;

  static String? _string(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static int? _int(Object? value) =>
      value is num ? value.toInt() : int.tryParse('$value');

  static double? _double(Object? value) =>
      value is num ? value.toDouble() : double.tryParse('$value');
}
