import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theming/app_colors.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_custom_button.dart';
import '../../../../core/widgets/app_filter_chip.dart';
import '../../domain/entities/accounting_overview.dart';
import '../cubit/cash_state.dart';
import '../cubit/sales_state.dart';
import '../helpers/accounting_format.dart';
import '../helpers/accounting_styles.dart';

import '../../../../core/localization/translations.dart';

/// What the sales filters sheet hands back.
class SalesFilters {
  final DateRangeFilter range;
  final PaymentMethod? method;
  final PaymentStatus? status;

  const SalesFilters({required this.range, this.method, this.status});
}

/// What the cash filters sheet hands back.
class CashFilters {
  final CashTypeFilter type;
  final DateRangeFilter range;

  const CashFilters({required this.type, required this.range});
}

/// "فلاتر" of the sales list: period, payment method and status, with apply and
/// reset.
class SalesFiltersSheet extends StatefulWidget {
  final SalesFilters initial;

  const SalesFiltersSheet({super.key, required this.initial});

  static Future<SalesFilters?> show(BuildContext context, SalesFilters initial) {
    return AppBottomSheet.show<SalesFilters>(
      context,
      builder: (_) => SalesFiltersSheet(initial: initial),
    );
  }

  @override
  State<SalesFiltersSheet> createState() => _SalesFiltersSheetState();
}

class _SalesFiltersSheetState extends State<SalesFiltersSheet> {
  late DateRangeFilter _range = widget.initial.range;
  PaymentMethod? _method;
  PaymentStatus? _status;

  @override
  void initState() {
    super.initState();
    _method = widget.initial.method;
    _status = widget.initial.status;
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomSheet(
      padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 24.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SheetTitle('فلاتر'.tr),
          _ChipGroup<DateRangeFilter>(
            title: 'الفترة'.tr,
            options: [for (final r in DateRangeFilter.values) (r, dateRangeLabel(r))],
            selected: _range,
            onSelected: (value) => setState(() => _range = value),
          ),
          _ChipGroup<PaymentMethod?>(
            title: 'طريقة الدفع'.tr,
            options: [
              (null, 'الكل'.tr),
              for (final m in PaymentMethod.values) (m, paymentMethodLabel(m)),
            ],
            selected: _method,
            onSelected: (value) => setState(() => _method = value),
          ),
          _ChipGroup<PaymentStatus?>(
            title: 'الحالة'.tr,
            options: [
              (null, 'الكل'.tr),
              for (final s in PaymentStatus.values) (s, paymentStatusLabel(s)),
            ],
            selected: _status,
            onSelected: (value) => setState(() => _status = value),
          ),
          SizedBox(height: 16.h),
          _ApplyRow(
            onApply: () => Navigator.of(context).pop(
              SalesFilters(range: _range, method: _method, status: _status),
            ),
            onReset: () => Navigator.of(context).pop(const SalesFilters(range: DateRangeFilter.all)),
          ),
        ],
      ),
    );
  }
}

/// "فلاتر" of the cash book: movement type and period.
class CashFiltersSheet extends StatefulWidget {
  final CashFilters initial;

  const CashFiltersSheet({super.key, required this.initial});

  static Future<CashFilters?> show(BuildContext context, CashFilters initial) {
    return AppBottomSheet.show<CashFilters>(
      context,
      builder: (_) => CashFiltersSheet(initial: initial),
    );
  }

  @override
  State<CashFiltersSheet> createState() => _CashFiltersSheetState();
}

class _CashFiltersSheetState extends State<CashFiltersSheet> {
  late CashTypeFilter _type = widget.initial.type;
  late DateRangeFilter _range = widget.initial.range;

  @override
  Widget build(BuildContext context) {
    return AppBottomSheet(
      padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 24.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SheetTitle('فلاتر'.tr),
          _ChipGroup<CashTypeFilter>(
            title: 'النوع'.tr,
            options: [for (final t in CashTypeFilter.values) (t, cashTypeFilterLabel(t))],
            selected: _type,
            onSelected: (value) => setState(() => _type = value),
          ),
          _ChipGroup<DateRangeFilter>(
            title: 'الفترة'.tr,
            options: [for (final r in DateRangeFilter.values) (r, dateRangeLabel(r))],
            selected: _range,
            onSelected: (value) => setState(() => _range = value),
          ),
          SizedBox(height: 16.h),
          _ApplyRow(
            onApply: () => Navigator.of(context).pop(CashFilters(type: _type, range: _range)),
            onReset: () => Navigator.of(context).pop(
              const CashFilters(type: CashTypeFilter.all, range: DateRangeFilter.all),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetTitle extends StatelessWidget {
  final String text;

  const _SheetTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 36.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
        ),
        SizedBox(height: 16.h),
        Text(text, style: AccountingStyles.sectionTitle),
        SizedBox(height: 8.h),
      ],
    );
  }
}

/// A titled row of single-choice chips.
class _ChipGroup<T> extends StatelessWidget {
  final String title;
  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onSelected;

  const _ChipGroup({
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 12.h),
        Text(title, style: AccountingStyles.label),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            for (final (value, label) in options)
              AppFilterChip(
                label: label,
                selected: value == selected,
                onTap: () => onSelected(value),
              ),
          ],
        ),
      ],
    );
  }
}

class _ApplyRow extends StatelessWidget {
  final VoidCallback onApply;
  final VoidCallback onReset;

  const _ApplyRow({required this.onApply, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: AppCustomButton(text: 'تطبيق'.tr, height: 48.h, onPressed: onApply)),
        SizedBox(width: 8.w),
        Expanded(
          child: AppCustomButton(
            text: 'إعادة تعيين'.tr,
            height: 48.h,
            backgroundColor: Colors.white,
            textColor: AppColors.mainTeal,
            borderColor: AppColors.cardBorder,
            onPressed: onReset,
          ),
        ),
      ],
    );
  }
}
