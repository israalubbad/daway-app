import '../../../../core/helpers/json_reader.dart';
import '../../domain/entities/cart_item.dart';

class CartItemModel {
  final int id;
  final int pharmacyId;
  final String pharmacyName;
  final String medicineName;
  final double price;
  final int quantity;

  const CartItemModel({
    required this.id,
    required this.pharmacyId,
    required this.pharmacyName,
    required this.medicineName,
    required this.price,
    required this.quantity,
  });

  /// The line's medicine can come from either the general catalog
  /// (`medicine`) or the MOH catalog (`moh_medicine`) depending on which one
  /// the pharmacy stocked it from — exactly one of the two is non-null.
  ///
  /// Numbers are read tolerantly (see [jsonDouble]): `price` arrives as a
  /// string when the backend serialises a decimal column.
  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final medicine = jsonMap(json['medicine']);
    final mohMedicine = jsonMap(json['moh_medicine']);
    final pharmacy = jsonMap(json['pharmacy']);
    final name = jsonString(medicine?['trade_name']) ??
        jsonString(mohMedicine?['trade_name']) ??
        jsonString(json['medicine_name']) ??
        '';

    return CartItemModel(
      id: jsonInt(json['id']) ?? 0,
      pharmacyId: jsonInt(json['pharmacy_id']) ?? jsonInt(pharmacy?['id']) ?? 0,
      pharmacyName: jsonString(json['pharmacy_name']) ??
          jsonString(pharmacy?['pharmacy_name']) ??
          jsonString(pharmacy?['name']) ??
          '',
      medicineName: name,
      price: jsonDouble(json['price']) ?? jsonDouble(json['unit_price']) ?? 0,
      quantity: jsonInt(json['quantity']) ?? 1,
    );
  }

  CartItem toEntity() => CartItem(
        id: id,
        pharmacyId: pharmacyId,
        pharmacyName: pharmacyName,
        medicineName: medicineName,
        price: price,
        quantity: quantity,
      );
}
