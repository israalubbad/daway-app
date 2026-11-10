import '../../../../core/erroring/failure.dart';
import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../../../auth/domain/usecases/with_session_token.dart';
import '../entities/accounting_customer.dart';
import '../entities/accounting_overview.dart';
import '../entities/cash_ledger.dart';
import '../entities/refund_record.dart';
import '../entities/sale_invoice.dart';
import '../repositories/accounting_repository.dart';


ApiResult<T> _refuse<T>(String message) => ApiError(ApiFailure(message: message));

class GetAccountingOverviewUseCase {
  final AccountingRepository _repository;
  final SessionRepository _sessions;

  const GetAccountingOverviewUseCase(this._repository, this._sessions);

  Future<ApiResult<AccountingOverview>> call(SalesPeriod period, {bool useCache = false}) =>
      withSessionToken(
        _sessions,
        (token) => _repository.getOverview(token: token, period: period, useCache: useCache),
      );
}

class GetSalesUseCase {
  final AccountingRepository _repository;
  final SessionRepository _sessions;

  const GetSalesUseCase(this._repository, this._sessions);

  Future<ApiResult<List<SaleInvoice>>> call() =>
      withSessionToken(_sessions, (token) => _repository.getSales(token: token));
}

class GetInvoiceUseCase {
  final AccountingRepository _repository;
  final SessionRepository _sessions;

  const GetInvoiceUseCase(this._repository, this._sessions);

  Future<ApiResult<SaleInvoice>> call(String number) =>
      withSessionToken(_sessions, (token) => _repository.getInvoice(token: token, number: number));
}

class GetRefundableLinesUseCase {
  final AccountingRepository _repository;
  final SessionRepository _sessions;

  const GetRefundableLinesUseCase(this._repository, this._sessions);

  /// The lines of [invoice] with units left to return; a closed invoice has
  /// none to offer.
  Future<ApiResult<List<InvoiceLine>>> call(SaleInvoice invoice) {
    if (invoice.isClosed) {
      return Future.value(_refuse('الفاتورة ملغاة أو مرجوعة ولا يمكن إرجاع أصناف منها'));
    }
    return withSessionToken(
      _sessions,
      (token) => _repository.getRefundableLines(token: token, number: invoice.number),
    );
  }
}

class GetRefundsUseCase {
  final AccountingRepository _repository;
  final SessionRepository _sessions;

  const GetRefundsUseCase(this._repository, this._sessions);

  Future<ApiResult<List<RefundRecord>>> call() =>
      withSessionToken(_sessions, (token) => _repository.getRefunds(token: token));
}

class GetCashLedgerUseCase {
  final AccountingRepository _repository;
  final SessionRepository _sessions;

  const GetCashLedgerUseCase(this._repository, this._sessions);

  Future<ApiResult<CashLedger>> call() =>
      withSessionToken(_sessions, (token) => _repository.getCashLedger(token: token));
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
    if (!CashMovementRules.isValidAmount(amount)) {
      return Future.value(_refuse('أدخل مبلغاً أكبر من صفر'));
    }
    if (!CashMovementRules.isValidReason(reason)) {
      return Future.value(_refuse('اذكر سبب الحركة (3 أحرف على الأقل)'));
    }
    return withSessionToken(
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
    return withSessionToken(
      _sessions,
      (token) => _repository.searchSaleItems(token: token, query: trimmed),
    );
  }
}

class FindSaleItemByBarcodeUseCase {
  final AccountingRepository _repository;
  final SessionRepository _sessions;

  const FindSaleItemByBarcodeUseCase(this._repository, this._sessions);

  /// A barcode is digits only, 8, 12, 13 or 14 of them (what the backend
  /// accepts); spaces and dashes a scanner or a hand may add are dropped.
  Future<ApiResult<SaleItemOption?>> call(String barcode) {
    final digits = barcode.replaceAll(RegExp(r'[\s-]'), '');
    if (!RegExp(r'^\d+$').hasMatch(digits) || ![8, 12, 13, 14].contains(digits.length)) {
      return Future.value(_refuse('صيغة الباركود غير مدعومة'));
    }
    return withSessionToken(_sessions, (token) => _repository.findByBarcode(token: token, barcode: digits));
  }
}

class SearchCustomersUseCase {
  final AccountingRepository _repository;
  final SessionRepository _sessions;

  const SearchCustomersUseCase(this._repository, this._sessions);

  Future<ApiResult<List<AccountingCustomer>>> call(String query) {
    final trimmed = query.trim();
    if (trimmed.length < 2) return Future.value(const Success(<AccountingCustomer>[]));
    return withSessionToken(
      _sessions,
      (token) => _repository.searchCustomers(token: token, query: trimmed),
    );
  }
}

/// Records a payment against an invoice, through its customer: the backend has
/// no payment on an invoice without one. More than zero, no more than what is
/// still owed, and not by "credit".
class RecordInvoicePaymentUseCase {
  final AccountingRepository _repository;
  final SessionRepository _sessions;

  const RecordInvoicePaymentUseCase(this._repository, this._sessions);

  Future<ApiResult<void>> call({
    required SaleInvoice invoice,
    required double amount,
    required PaymentMethod method,
  }) {
    if (invoice.isClosed) {
      return Future.value(_refuse('الفاتورة ملغاة أو مرجوعة'));
    }
    if (invoice.customerId == null) {
      return Future.value(_refuse('لا يمكن تسجيل دفعة على فاتورة بلا عميل'));
    }
    if (method == PaymentMethod.credit) {
      return Future.value(_refuse('اختر طريقة دفع: نقداً أو بطاقة أو حوالة بنكية'));
    }
    if (!PaymentRules.isValidAmount(amount, remaining: invoice.remaining)) {
      return Future.value(_refuse('أدخل مبلغاً أكبر من صفر ولا يزيد عن المتبقي'));
    }
    return withSessionToken(
      _sessions,
      (token) => _repository.recordInvoicePayment(
        token: token,
        invoice: invoice,
        amount: amount,
        method: method,
      ),
    );
  }
}

/// Returns goods from an invoice: at least one unit, none beyond what is left.
class CreateRefundUseCase {
  final AccountingRepository _repository;
  final SessionRepository _sessions;

  const CreateRefundUseCase(this._repository, this._sessions);

  Future<ApiResult<void>> call(RefundRequest request) {
    if (!request.isValid) {
      return Future.value(_refuse('اختر وحدة واحدة على الأقل ولا تتجاوز الكمية المتاحة'));
    }
    return withSessionToken(
      _sessions,
      (token) => _repository.createRefund(
        token: token,
        invoiceNumber: request.invoiceNumber,
        quantities: {
          for (final e in request.quantities.entries)
            if (e.value > 0) e.key: e.value,
        },
      ),
    );
  }
}

/// Saves the sale. An empty cart is refused, a payment above the total is
/// capped to it (change is not money received), and a sale on credit needs a
/// customer to owe it.
class CreateSaleUseCase {
  final AccountingRepository _repository;
  final SessionRepository _sessions;

  const CreateSaleUseCase(this._repository, this._sessions);

  Future<ApiResult<void>> call(NewSale sale) {
    if (sale.lines.isEmpty) {
      return Future.value(_refuse('السلة فارغة'));
    }
    if (sale.method == PaymentMethod.credit && sale.customerId == null) {
      return Future.value(_refuse('اختر عميلاً للبيع بالدين'));
    }
    final total = sale.lines.fold<double>(0, (sum, line) => sum + line.total);
    final paid = sale.paid;
    final capped = NewSale(
      customerId: sale.customerId,
      customerName: sale.customerName,
      lines: sale.lines,
      paid: paid?.clamp(0, total).toDouble(),
      method: sale.method,
    );
    return withSessionToken(_sessions, (token) => _repository.createSale(token: token, sale: capped));
  }
}
