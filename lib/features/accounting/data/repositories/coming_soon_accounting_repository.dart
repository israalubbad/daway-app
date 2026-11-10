import '../../../../core/erroring/failure.dart';
import '../../../../core/helpers/api_result.dart';
import '../../domain/entities/accounting_overview.dart';
import '../../domain/entities/cash_ledger.dart';
import '../../domain/entities/refund_record.dart';
import '../../domain/entities/sale_invoice.dart';
import '../../domain/repositories/accounting_repository.dart';

/// Stands in for the accounting API until its response shapes are known (the
/// routes exist under `/pharmacy/accounting/*`, but no sample of any response
/// has been seen). Every call answers [ComingSoonFailure], so a release build
/// shows "قريباً" instead of figures nobody recorded.
class ComingSoonAccountingRepository implements AccountingRepository {
  const ComingSoonAccountingRepository();

  static const _failure = ApiError<Never>(ComingSoonFailure());

  @override
  Future<ApiResult<AccountingOverview>> getOverview({
    required String token,
    required SalesPeriod period,
  }) async => _failure;

  @override
  Future<ApiResult<List<SaleInvoice>>> getSales({required String token}) async => _failure;

  @override
  Future<ApiResult<List<RefundRecord>>> getRefunds({required String token}) async => _failure;

  @override
  Future<ApiResult<CashLedger>> getCashLedger({required String token}) async => _failure;

  @override
  Future<ApiResult<void>> recordCashMovement({
    required String token,
    required bool isDeposit,
    required double amount,
    required String reason,
  }) async => _failure;

  @override
  Future<ApiResult<List<SaleItemOption>>> searchSaleItems({
    required String token,
    required String query,
  }) async => _failure;

  @override
  Future<ApiResult<SaleItemOption?>> findByBarcode({
    required String token,
    required String barcode,
  }) async => _failure;

  @override
  Future<ApiResult<void>> createSale({required String token, required NewSale sale}) async =>
      _failure;

  @override
  Future<ApiResult<void>> recordInvoicePayment({
    required String token,
    required int invoiceId,
    required double amount,
    required PaymentMethod method,
  }) async => _failure;

  @override
  Future<ApiResult<void>> createRefund({
    required String token,
    required int invoiceId,
    required Map<int, int> quantities,
  }) async => _failure;
}
