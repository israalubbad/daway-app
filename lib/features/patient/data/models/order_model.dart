import '../../../../core/helpers/server_timestamp.dart';
import '../../../../core/helpers/json_parsing.dart';
import '../../domain/entities/order.dart';

class OrderModel {
  final String orderNumber;
  final int? pharmacyId;
  final String pharmacyName;
  final OrderStatus status;
  final int itemsCount;
  final double price;
  final String address;
  final DateTime createdAt;

  const OrderModel({
    this.pharmacyId,
    required this.orderNumber,
    required this.pharmacyName,
    required this.status,
    required this.itemsCount,
    required this.price,
    required this.address,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final pharmacy = jsonMap(json['pharmacy']);
    final address = jsonMap(json['address']);
    final createdAtRaw = jsonString(json['created_at']);

    return OrderModel(
      pharmacyId: jsonInt(pharmacy?['id']) ?? jsonInt(json['pharmacy_id']),
      orderNumber: jsonInt(json['id'])?.toString() ?? '',
      pharmacyName: jsonString(pharmacy?['name']) ?? '',
      status: OrderStatus.fromApi(jsonString(json['status']) ?? ''),
      itemsCount: jsonInt(json['items_count']) ?? 0,
      price: jsonDouble(json['total']) ?? jsonDouble(json['grand_total']) ?? 0,
      address: jsonString(address?['address']) ?? jsonString(address?['label']) ?? '',
      createdAt: tryParseServerTimestamp(createdAtRaw) ?? DateTime.now(),
    );
  }

  Order toEntity() => Order(
        pharmacyId: pharmacyId,
        orderNumber: orderNumber,
        pharmacyName: pharmacyName,
        status: status,
        itemsCount: itemsCount,
        price: price,
        address: address,
        createdAt: createdAt,
      );
}
