import '../../../../core/helpers/api_result.dart';
import '../entities/accounting_customer.dart';
import '../entities/accounting_overview.dart';
import '../entities/cash_ledger.dart';
import '../entities/refund_record.dart';
import '../entities/sale_invoice.dart';

abstract interface class AccountingRepository {
  /// The overview for [period]. The backend answers every period at once and
  /// is slow (up to a minute), so with [useCache] a recent answer is reused:
  /// switching the chart's period does not ask again.
  Future<ApiResult<AccountingOverview>> getOverview({
    required String token,
    required SalesPeriod period,
    bool useCache = false,
  });

  Future<ApiResult<List<SaleInvoice>>> getSales({required String token});

  /// One invoice with its lines.
  Future<ApiResult<SaleInvoice>> getInvoice({required String token, required String number});

  /// The lines of an invoice that can still be returned, each carrying the
  /// units left to return as its quantity.
  Future<ApiResult<List<InvoiceLine>>> getRefundableLines({
    required String token,
    required String number,
  });

  Future<ApiResult<List<RefundRecord>>> getRefunds({required String token});

  Future<ApiResult<CashLedger>> getCashLedger({required String token});

  /// Records a manual cash movement: a deposit, or a withdrawal when
  /// [isDeposit] is false. [amount] is positive either way.
  Future<ApiResult<void>> recordCashMovement({
    required String token,
    required bool isDeposit,
    required double amount,
    required String reason,
  });

  /// Medicines matching [query] (by name or active ingredient).
  Future<ApiResult<List<SaleItemOption>>> searchSaleItems({
    required String token,
    required String query,
  });

  /// The medicine carrying [barcode] in this pharmacy's stock, or null when
  /// the barcode is not in the catalogue. A medicine that is known but cannot
  /// be sold (out of stock, not sold here, ambiguous) comes back as a failure
  /// saying why.
  Future<ApiResult<SaleItemOption?>> findByBarcode({
    required String token,
    required String barcode,
  });

  Future<ApiResult<List<AccountingCustomer>>> searchCustomers({
    required String token,
    required String query,
  });

  Future<ApiResult<void>> createSale({required String token, required NewSale sale});

  /// Records a payment of [amount] against the invoice, through its customer.
  Future<ApiResult<void>> recordInvoicePayment({
    required String token,
    required SaleInvoice invoice,
    required double amount,
    required PaymentMethod method,
  });

  /// Returns units of an invoice: [quantities] maps invoice line id to units.
  Future<ApiResult<void>> createRefund({
    required String token,
    required String invoiceNumber,
    required Map<int, int> quantities,
  });
}
