/// A customer of the pharmacy, as the invoice form's customer search shows it.
class AccountingCustomer {
  final int id;
  final String name;
  final String? phone;

  /// What the customer owes now.
  final double balance;

  const AccountingCustomer({
    required this.id,
    required this.name,
    this.phone,
    this.balance = 0,
  });
}
