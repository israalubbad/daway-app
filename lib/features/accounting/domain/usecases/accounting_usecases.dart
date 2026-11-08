import '../../../../core/erroring/failure.dart';
import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../entities/accounting_overview.dart';
import '../entities/cash_ledger.dart';
import '../entities/refund_record.dart';
import '../entities/sale_invoice.dart';
import '../repositories/accounting_repository.dart';

/// Runs [action] with the signed-in pharmacy's token, or answers the
/// session-expired failure when there is none. Every accounting use case
/// below is this plus one repository call.
Future<ApiResult<T>> _withToken<T>(
  SessionRepository sessions,
  Future<ApiResult<T>> Function(String token) action,
) async {
  final session = await sessions.getSession();
  if (session == null) {
    return const ApiError(
      ApiFailure(message: 'انتهت صلاحية الجلسة، يرجى تسجيل الدخول مرة أخرى'),
    );
  }
  return action(session.token);
}

class GetAccountingOverviewUseCase {
  final AccountingRepository _repository;
  final SessionRepository _sessions;

  const GetAccountingOverviewUseCase(this._repository, this._sessions);

  Future<ApiResult<AccountingOverview>> call(SalesPeriod period) =>
      _withToken(_sessions, (token) => _repository.getOverview(token: token, period: period));
}

class GetSalesUseCase {
  final AccountingRepository _repository;
  final SessionRepository _sessions;

  const GetSalesUseCase(this._repository, this._sessions);

  Future<ApiResult<List<SaleInvoice>>> call() =>
      _withToken(_sessions, (token) => _repository.getSales(token: token));
}

class GetRefundsUseCase {
  final AccountingRepository _repository;
  final SessionRepository _sessions;

  const GetRefundsUseCase(this._repository, this._sessions);

  Future<ApiResult<List<RefundRecord>>> call() =>
      _withToken(_sessions, (token) => _repository.getRefunds(token: token));
}

class GetCashLedgerUseCase {
  final AccountingRepository _repository;
  final SessionRepository _sessions;

  const GetCashLedgerUseCase(this._repository, this._sessions);

  Future<ApiResult<CashLedger>> call() =>
      _withToken(_sessions, (token) => _repository.getCashLedger(token: token));
}

/// Records a manual cash movement after checking what the user typed: the
/// amount must be above zero and the reason must say something.
class RecordCashMovementUseCase {
  final AccountingRepository _repository;
  final SessionRepository _sessions;

  const RecordCashMovementUseCase(this._repository, this._sessions);

  Future<ApiResult<void>> call({
    required bool isDeposit,
    required double amount,
    required String reason,
  }) {
    if (amount <= 0) {
      return Future.value(const ApiError(ApiFailure(message: 'أدخل مبلغاً أكبر من صفر')));
    }
    if (reason.trim().isEmpty) {
      return Future.value(const ApiError(ApiFailure(message: 'اذكر سبب الحركة')));
    }
    return _withToken(
      _sessions,
      (token) => _repository.recordCashMovement(
        token: token,
        isDeposit: isDeposit,
        amount: amount,
        reason: reason.trim(),
      ),
    );
  }
}

class SearchSaleItemsUseCase {
  final AccountingRepository _repository;
  final SessionRepository _sessions;

  const SearchSaleItemsUseCase(this._repository, this._sessions);

  /// The search needs at least two characters; with fewer there is nothing to
  /// look for, and an empty list comes back.
  Future<ApiResult<List<SaleItemOption>>> call(String query) {
    final trimmed = query.trim();
    if (trimmed.length < 2) return Future.value(const Success(<SaleItemOption>[]));
    return _withToken(
      _sessions,
      (token) => _repository.searchSaleItems(token: token, query: trimmed),
    );
  }
}

class FindSaleItemByBarcodeUseCase {
  final AccountingRepository _repository;
  final SessionRepository _sessions;

  const FindSaleItemByBarcodeUseCase(this._repository, this._sessions);

  Future<ApiResult<SaleItemOption?>> call(String barcode) =>
      _withToken(_sessions, (token) => _repository.findByBarcode(token: token, barcode: barcode.trim()));
}

/// Saves the sale. An empty cart is refused, and a payment above the total is
/// capped to it: change is not recorded as money received.
class CreateSaleUseCase {
  final AccountingRepository _repository;
  final SessionRepository _sessions;

  const CreateSaleUseCase(this._repository, this._sessions);

  Future<ApiResult<void>> call(NewSale sale) {
    if (sale.lines.isEmpty) {
      return Future.value(const ApiError(ApiFailure(message: 'السلة فارغة')));
    }
    final total = sale.lines.fold<double>(0, (sum, line) => sum + line.total);
    final capped = NewSale(
      customerName: sale.customerName,
      lines: sale.lines,
      paid: sale.paid.clamp(0, total).toDouble(),
      method: sale.method,
    );
    return _withToken(_sessions, (token) => _repository.createSale(token: token, sale: capped));
  }
}
