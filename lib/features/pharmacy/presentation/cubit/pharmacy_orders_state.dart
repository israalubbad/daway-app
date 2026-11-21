import '../../domain/entities/pharmacy_order.dart';

sealed class PharmacyOrdersState {
  const PharmacyOrdersState();
}

class PharmacyOrdersLoading extends PharmacyOrdersState {
  const PharmacyOrdersLoading();
}

class PharmacyOrdersLoadFailure extends PharmacyOrdersState {
  final String message;

  const PharmacyOrdersLoadFailure(this.message);
}

class PharmacyOrdersLoaded extends PharmacyOrdersState {
  final List<PharmacyOrder> orders;

  const PharmacyOrdersLoaded(this.orders);
}
