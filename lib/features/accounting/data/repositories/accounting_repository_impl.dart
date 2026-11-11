import '../../../../core/erroring/error_handler.dart';
import '../../../../core/erroring/failure.dart';
import '../../../../core/helpers/api_result.dart';
import '../../../../core/helpers/json_list_extractor.dart';
import '../../../../core/helpers/paginated_fetch.dart';
import '../../domain/entities/accounting_customer.dart';
import '../../domain/entities/accounting_overview.dart';
import '../../domain/entities/cash_ledger.dart';
import '../../domain/entities/refund_record.dart';
import '../../domain/entities/sale_invoice.dart';
import '../../domain/repositories/accounting_repository.dart';
import '../datasources/accounting_remote_data_source.dart';
import '../models/accounting_parsers.dart';

import '../../../../core/localization/translations.dart';

class AccountingRepositoryImpl implements AccountingRepository {
  final AccountingRemoteDataSource _remote;

  AccountingRepositoryImpl(this._remote);

  /// The last overview answer. The backend gives every period in one slow
  /// response, so switching the chart's period reuses it for a short while.
  Map<String, dynamic>? _overviewBody;
  DateTime? _overviewFetchedAt;
  static const _overviewTtl = Duration(minutes: 2);

  @override
  Future<ApiResult<AccountingOverview>> getOverview({
    required String token,
    required SalesPeriod period,
    bool useCache = false,
  }) {
    return guardApi(() async {
      final fetchedAt = _overviewFetchedAt;
      final cached = _overviewBody;
      final fresh = useCache &&
          cached != null &&
          fetchedAt != null &&
          DateTime.now().difference(fetchedAt) < _overviewTtl;
      if (!fresh) {
        final response = await _remote.getOverview(token: token, range: overviewRangeOf(period));
        final body = response.data;
        if (body is! Map<String, dynamic>) {
          throw FormatException('Unexpected overview response: $body');
        }
        _overviewBody = body;
        _overviewFetchedAt = DateTime.now();
      }
      return Success(parseOverview(_overviewBody!, period));
    });
  }

  @override
  Future<ApiResult<List<SaleInvoice>>> getSales({required String token}) {
    return guardApi(() async {
      final json = await fetchAllPages(
        source: 'GET /pharmacy/accounting/sales',
        fetchPage: (page) async => (await _remote.getSales(token: token, page: page)).data,
      );
      return Success(_parseEach(json, parseInvoice));
    });
  }

  @override
  Future<ApiResult<SaleInvoice>> getInvoice({required String token, required String number}) {
    return guardApi(() async {
      final response = await _remote.getSale(token: token, number: number);
      return Success(parseInvoice(dataOf(response.data)));
    });
  }

  @override
  Future<ApiResult<List<InvoiceLine>>> getRefundableLines({
    required String token,
    required String number,
  }) {
    return guardApi(() async {
      final response = await _remote.getRefundItems(token: token, number: number);
      return Success(parseRefundableLines(dataOf(response.data)));
    });
  }

  @override
  Future<ApiResult<List<RefundRecord>>> getRefunds({required String token}) {
    return guardApi(() async {
      final response = await _remote.getRefunds(token: token);
      final json = extractJsonList(response.data, source: 'GET /pharmacy/accounting/refunds');
      return Success(_parseEach(json, parseRefund));
    });
  }

  @override
  Future<ApiResult<CashLedger>> getCashLedger({required String token}) {
    return guardApi(() async {
      final response = await _remote.getCash(token: token);
      return Success(parseCashLedger(response.data));
    });
  }

  @override
  Future<ApiResult<void>> recordCashMovement({
    required String token,
    required bool isDeposit,
    required double amount,
    required String reason,
  }) {
    return guardApi(() async {
      await _remote.createCashAdjustment(
        token: token,
        body: {
          'direction': isDeposit ? 'in' : 'out',
          'kind': isDeposit ? 'deposit' : 'withdrawal',
          'amount': amount,
          'reason': reason,
        },
      );
      return const Success(null);
    });
  }

  @override
  Future<ApiResult<List<SaleItemOption>>> searchSaleItems({
    required String token,
    required String query,
  }) {
    return guardApi(() async {
      final response = await _remote.searchMedicines(token: token, query: query);
      return Success(parseStockSearch(response.data));
    });
  }

  @override
  Future<ApiResult<SaleItemOption?>> findByBarcode({
    required String token,
    required String barcode,
  }) {
    return guardApi(() async {
      final response = await _remote.getBarcode(token: token, barcode: barcode);
      return barcodeLookupResult(dataOf(response.data), barcode);
    });
  }

  @override
  Future<ApiResult<List<AccountingCustomer>>> searchCustomers({
    required String token,
    required String query,
  }) {
    return guardApi(() async {
      final response = await _remote.getCustomers(token: token, search: query);
      final json = extractJsonList(response.data, source: 'GET /pharmacy/accounting/customers');
      return Success(_parseEach(json, parseCustomer));
    });
  }

  @override
  Future<ApiResult<void>> createSale({required String token, required NewSale sale}) {
    return guardApi(() async {
      await _remote.createSale(token: token, body: saleRequestBody(sale));
      return const Success(null);
    });
  }

  @override
  Future<ApiResult<void>> recordInvoicePayment({
    required String token,
    required SaleInvoice invoice,
    required double amount,
    required PaymentMethod method,
  }) async {
    final customerId = invoice.customerId;
    if (customerId == null) {
      return ApiError(ApiFailure(message: 'لا يمكن تسجيل دفعة على فاتورة بلا عميل'.tr));
    }
    try {
      await _remote.createCustomerPayment(
        token: token,
        customerId: customerId,
        body: {
          'amount': amount,
          'payment_method': paymentMethodApiValue(method),
          'sale_id': invoice.id,
          'description': 'دفعة على الفاتورة ${invoice.number}',
        },
      );
      return const Success(null);
    } catch (e) {
      return ApiError(mapExceptionToFailure(e));
    }
  }

  @override
  Future<ApiResult<void>> createRefund({
    required String token,
    required String invoiceNumber,
    required Map<int, int> quantities,
  }) {
    return guardApi(() async {
      await _remote.createRefund(
        token: token,
        body: {
          'sale_number': invoiceNumber,
          'items': [
            for (final e in quantities.entries) {'sale_item_id': e.key, 'quantity': e.value},
          ],
        },
      );
      return const Success(null);
    });
  }

  /// One malformed record is skipped rather than failing the whole list, like
  /// the other list parsers of the app.
  List<T> _parseEach<T>(List<dynamic> json, T Function(Map<String, dynamic>) parse) {
    final items = <T>[];
    for (final record in json) {
      try {
        items.add(parse(record as Map<String, dynamic>));
      } catch (_) {
        // Skip just this record.
      }
    }
    return items;
  }
}
