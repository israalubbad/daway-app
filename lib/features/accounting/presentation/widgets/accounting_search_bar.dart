import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theming/app_colors.dart';
import '../helpers/accounting_styles.dart';

/// The search field of an accounting list, with the filters button beside it
/// (a count badge on it while filters are set).
class AccountingSearchBar extends StatefulWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback? onFiltersTap;
  final int activeFilters;

  const AccountingSearchBar({
    super.key,
    required this.hint,
    required this.onChanged,
    this.onFiltersTap,
    this.activeFilters = 0,
  });

  @override
  State<AccountingSearchBar> createState() => _AccountingSearchBarState();
}

class _AccountingSearchBarState extends State<AccountingSearchBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48.h,
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.cardBorder),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Icon(Icons.search, size: 20.r, color: AppColors.authInputBorder),
                SizedBox(width: 8.w),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onChanged: widget.onChanged,
                    textInputAction: TextInputAction.search,
                    style: AccountingStyles.body,
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: widget.hint,
                      hintStyle: AccountingStyles.muted.copyWith(fontSize: 13.sp),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.onFiltersTap != null) ...[
          SizedBox(width: 8.w),
          Badge(
            isLabelVisible: widget.activeFilters > 0,
            label: Text('${widget.activeFilters}'),
            backgroundColor: AppColors.mainTeal,
            child: InkWell(
              onTap: widget.onFiltersTap,
              borderRadius: BorderRadius.circular(8.r),
              child: Container(
                width: 48.r,
                height: 48.r,
                decoration: BoxDecoration(
                  color: AppColors.permissionIconBg,
                  border: Border.all(color: AppColors.iconBlueBorder),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(Icons.tune_rounded, size: 22.r, color: AppColors.mainTeal),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
