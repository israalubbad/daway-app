import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/di/dependency_injection.dart';
import '../../../../core/theming/app_colors.dart';
import '../../../../core/widgets/app_custom_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../pharmacy/presentation/widgets/pharmacy_products_header.dart';
import '../../domain/entities/sale_invoice.dart';
import '../cubit/new_sale_cubit.dart';
import '../cubit/new_sale_state.dart';
import '../helpers/accounting_styles.dart';
import '../widgets/accounting_card.dart';
import '../widgets/sale_summary_sheet.dart';
import 'barcode_scanner_screen.dart';

/// "فاتورة بيع جديدة": scan or search medicines into the cart, then complete the
/// sale from the summary sheet. Pops with true once a sale was saved, so the
/// screen that opened it can refresh.
class NewSaleScreen extends StatelessWidget {
  const NewSaleScreen({super.key});

  /// Pushes the screen; completes with true when a sale was saved.
  static Future<bool?> open(BuildContext context) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const NewSaleScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<NewSaleCubit>(),
      child: const _NewSaleView(),
    );
  }
}

class _NewSaleView extends StatefulWidget {
  const _NewSaleView();

  @override
  State<_NewSaleView> createState() => _NewSaleViewState();
}

class _NewSaleViewState extends State<_NewSaleView> {
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _barcodeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _submitBarcode(NewSaleCubit cubit) async {
    final code = _barcodeController.text;
    await cubit.barcodeSubmitted(code);
    _barcodeController.clear();
  }

  /// Opens the camera; a scanned code goes through the same lookup as a typed
  /// one, and its medicine lands in the cart.
  Future<void> _scan(BuildContext context, NewSaleCubit cubit) async {
    final code = await BarcodeScannerScreen.scan(context);
    if (code == null || code.isEmpty) return;
    await cubit.barcodeSubmitted(code);
  }

  Future<void> _openSummary(BuildContext context) async {
    final cubit = context.read<NewSaleCubit>();
    final saved = await SaleSummarySheet.show(context, cubit);
    if (saved != true || !context.mounted) return;
    AppSnackbar.show(context, 'تم إتمام البيع');
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<NewSaleCubit>();
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<NewSaleCubit, NewSaleState>(
          builder: (context, state) {
            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 16.h),
                    children: [
                      PharmacyProductsHeader(
                        title: 'فاتورة بيع جديدة',
                        subtitle: 'امسح الباركود أو ابحث عن الدواء ثم أضفه للسلة',
                        onBack: () => Navigator.of(context).pop(),
                      ),
                      SizedBox(height: 16.h),
                      _ScanCard(
                        barcodeController: _barcodeController,
                        searchController: _searchController,
                        state: state,
                        onScanTap: () => _scan(context, cubit),
                        onBarcodeSubmitted: () => _submitBarcode(cubit),
                        onQueryChanged: cubit.queryChanged,
                        onItemTap: (item) {
                          cubit.addItem(item);
                          _searchController.clear();
                        },
                      ),
                      SizedBox(height: 16.h),
                      _CartCard(state: state, cubit: cubit),
                    ],
                  ),
                ),
                _CheckoutBar(state: state, onCheckout: () => _openSummary(context)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ScanCard extends StatelessWidget {
  final TextEditingController barcodeController;
  final TextEditingController searchController;
  final NewSaleState state;
  final VoidCallback onScanTap;
  final VoidCallback onBarcodeSubmitted;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<SaleItemOption> onItemTap;

  const _ScanCard({
    required this.barcodeController,
    required this.searchController,
    required this.state,
    required this.onScanTap,
    required this.onBarcodeSubmitted,
    required this.onQueryChanged,
    required this.onItemTap,
  });

  InputDecoration _decoration(String hint, {Widget? suffix}) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.r),
      borderSide: BorderSide(color: color),
    );
    return InputDecoration(
      isDense: true,
      hintText: hint,
      hintStyle: AccountingStyles.muted.copyWith(fontSize: 13.sp),
      suffixIcon: suffix,
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      enabledBorder: border(AppColors.cardBorder),
      focusedBorder: border(AppColors.mainTeal),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AccountingCard(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('شاشة البيع', style: AccountingStyles.sectionTitle),
          Text('ابدأ بمسح الباركود أو البحث بالاسم', style: AccountingStyles.muted),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: barcodeController,
                  textDirection: TextDirection.ltr,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => onBarcodeSubmitted(),
                  style: AccountingStyles.body.copyWith(fontFamily: 'monospace'),
                  decoration: _decoration('امسح الباركود أو اكتبه…'),
                ),
              ),
              SizedBox(width: 8.w),
              InkWell(
                onTap: onScanTap,
                borderRadius: BorderRadius.circular(8.r),
                child: Container(
                  width: 46.r,
                  height: 46.r,
                  decoration: BoxDecoration(
                    color: AppColors.mainTeal,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(Icons.qr_code_scanner_rounded, size: 24.r, color: Colors.white),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text('يدعم EAN-13 · EAN-8 · UPC-A · GTIN-14', style: AccountingStyles.muted),
          if (state.recognized != null) ...[
            SizedBox(height: 8.h),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: _Recognized(name: state.recognized!.name),
            ),
          ],
          if (state.barcodeMessage != null) ...[
            SizedBox(height: 8.h),
            Text(
              state.barcodeMessage!,
              style: AccountingStyles.label.copyWith(color: AppColors.logoutRed),
            ),
          ],
          SizedBox(height: 16.h),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                child: Text('أو', style: AccountingStyles.muted),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          SizedBox(height: 12.h),
          Text('ابحث عن دواء', style: AccountingStyles.label),
          SizedBox(height: 6.h),
          TextField(
            controller: searchController,
            onChanged: onQueryChanged,
            decoration: _decoration(
              'اكتب اسم الدواء أو المادة الفعالة…',
              suffix: Icon(Icons.search, size: 20.r, color: AppColors.authInputBorder),
            ),
          ),
          SizedBox(height: 4.h),
          Text('اكتب حرفين على الأقل للبحث', style: AccountingStyles.muted),
          if (state.isSearching)
            Padding(
              padding: EdgeInsets.only(top: 12.h),
              child: const Center(child: CircularProgressIndicator()),
            )
          else if (state.query.trim().length >= 2 && state.results.isEmpty)
            Padding(
              padding: EdgeInsets.only(top: 12.h),
              child: Text('لا توجد نتائج', style: AccountingStyles.muted),
            )
          else
            for (final item in state.results)
              InkWell(
                onTap: () => onItemTap(item),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name, style: AccountingStyles.cardTitle),
                            Text('المتوفر: ${item.stock}', style: AccountingStyles.muted),
                          ],
                        ),
                      ),
                      MoneyText(item.price, style: AccountingStyles.cardTitle),
                      SizedBox(width: 8.w),
                      Icon(Icons.add_circle_outline_rounded, size: 22.r, color: AppColors.mainTeal),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _Recognized extends StatelessWidget {
  final String name;

  const _Recognized({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: AppColors.productAvailableTint,
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 14.r, color: AppColors.productAvailableText),
          SizedBox(width: 4.w),
          Flexible(
            child: Text(
              'تم التعرف على الدواء: $name',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AccountingStyles.label.copyWith(color: AppColors.productAvailableText),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartCard extends StatelessWidget {
  final NewSaleState state;
  final NewSaleCubit cubit;

  const _CartCard({required this.state, required this.cubit});

  @override
  Widget build(BuildContext context) {
    return AccountingCard(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('أصناف السلة', style: AccountingStyles.sectionTitle)),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppColors.permissionIconBg,
                  border: Border.all(color: AppColors.iconBlueBorder),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text('${state.itemsCount}', style: AccountingStyles.label.copyWith(color: AppColors.mainTeal)),
              ),
            ],
          ),
          if (state.lines.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 28.h),
              child: Column(
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 36.r, color: AppColors.authInputBorder),
                  SizedBox(height: 8.h),
                  Text('السلة فارغة', style: AccountingStyles.cardTitle),
                  Text('امسح باركود أو ابحث عن دواء لإضافته', style: AccountingStyles.muted),
                ],
              ),
            )
          else
            for (final line in state.lines)
              Padding(
                padding: EdgeInsets.only(top: 12.h),
                child: _CartLineTile(line: line, cubit: cubit),
              ),
        ],
      ),
    );
  }
}

class _CartLineTile extends StatelessWidget {
  final SaleLine line;
  final NewSaleCubit cubit;

  const _CartLineTile({required this.line, required this.cubit});

  @override
  Widget build(BuildContext context) {
    Widget stepButton(IconData icon, VoidCallback onTap, String label) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6.r),
      child: Semantics(
        button: true,
        label: label,
        child: Container(
          width: 30.r,
          height: 30.r,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.cardBorder),
            borderRadius: BorderRadius.circular(6.r),
          ),
          child: Icon(icon, size: 16.r, color: AppColors.mainTeal),
        ),
      ),
    );

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(line.item.name, style: AccountingStyles.cardTitle),
              Row(
                children: [
                  MoneyText(line.item.price, style: AccountingStyles.muted),
                  Text(' × ${line.quantity}', style: AccountingStyles.muted),
                ],
              ),
            ],
          ),
        ),
        stepButton(Icons.remove, () => cubit.quantityChanged(line.item.id, line.quantity - 1), 'تقليل الكمية'),
        SizedBox(
          width: 32.w,
          child: Text('${line.quantity}', textAlign: TextAlign.center, style: AccountingStyles.cardTitle),
        ),
        stepButton(Icons.add, () => cubit.quantityChanged(line.item.id, line.quantity + 1), 'زيادة الكمية'),
        SizedBox(width: 8.w),
        SizedBox(width: 64.w, child: MoneyText(line.total, style: AccountingStyles.cardTitle)),
        IconButton(
          onPressed: () => cubit.removeItem(line.item.id),
          icon: Icon(Icons.delete_outline_rounded, size: 20.r, color: AppColors.logoutRed),
          tooltip: 'حذف',
        ),
      ],
    );
  }
}

/// The bar fixed under the cart: the total and "إتمام البيع", off while the
/// cart is empty.
class _CheckoutBar extends StatelessWidget {
  final NewSaleState state;
  final VoidCallback onCheckout;

  const _CheckoutBar({required this.state, required this.onCheckout});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 12.h),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('الإجمالي', style: AccountingStyles.muted),
                MoneyText(state.total, style: AccountingStyles.amount),
              ],
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: AppCustomButton(
                text: 'إتمام البيع',
                height: 48.h,
                backgroundColor: state.canSubmit ? AppColors.mainTeal : AppColors.borderGrey,
                onPressed: state.canSubmit ? onCheckout : () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
