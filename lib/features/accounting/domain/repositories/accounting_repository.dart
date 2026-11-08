import '../../../../core/helpers/api_result.dart';
import '../entities/accounting_overview.dart';
import '../entities/cash_ledger.dart';
import '../entities/refund_record.dart';
import '../entities/sale_invoice.dart';

abstract interface class AccountingRepository {
  Future<ApiResult<AccountingOverview>> getOverview({
    required String token,
    required SalesPeriod period,
  });

  Future<ApiResult<List<SaleInvoice>>> getSales({required String token});

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

  /// The medicine carrying [barcode], or null when none does.
  Future<ApiResult<SaleItemOption?>> findByBarcode({
    required String token,
    required String barcode,
  });

  Future<ApiResult<void>> createSale({required String token, required NewSale sale});
}
