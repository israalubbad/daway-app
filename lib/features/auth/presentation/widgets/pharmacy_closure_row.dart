import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theming/app_colors.dart';
import '../../../../core/theming/app_text_styles.dart';
import '../../../../core/widgets/account_row_card.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../domain/entities/closure_request.dart';
import '../cubit/pharmacy_closure_cubit.dart';
import '../cubit/pharmacy_closure_state.dart';
import 'pharmacy_closure_sheet.dart';

import '../../../../core/localization/translations.dart';

/// The settings row where a pharmacy asks to close its account. While a
/// request is open the row shows where it stands and tapping it explains
/// instead of opening the form again.
///
/// Expects a [PharmacyClosureCubit] above it.
class PharmacyClosureRow extends StatelessWidget {
  const PharmacyClosureRow({super.key});

  static String _statusLabel(ClosureRequestStatus status) => switch (status) {
        ClosureRequestStatus.pending => 'قيد المراجعة'.tr,
        ClosureRequestStatus.approved => 'تمت الموافقة'.tr,
        ClosureRequestStatus.rejected => 'تم الرفض'.tr,
        ClosureRequestStatus.other => 'تم الإرسال'.tr,
      };

  static String _blockedMessage(ClosureRequestStatus status) =>
      status == ClosureRequestStatus.approved
          ? 'تمت الموافقة على طلب إغلاق حسابك'.tr
          : 'طلب إغلاق حسابك قيد المراجعة من الإدارة'.tr;

  void _onTap(BuildContext context, ClosureRequest? request) {
    if (request != null && request.blocksNewRequest) {
      AppSnackbar.show(context, _blockedMessage(request.status));
      return;
    }
    PharmacyClosureSheet.show(context, context.read<PharmacyClosureCubit>());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PharmacyClosureCubit, PharmacyClosureState>(
      // A request just went through: the sheet closes itself, and this is
      // where the user is told it arrived.
      listenWhen: closureRequestJustSent,
      listener: (context, state) =>
          AppSnackbar.show(context, 'تم إرسال طلب إغلاق الحساب، سيتم مراجعته من الإدارة'.tr),
      builder: (context, state) {
        final request = state is PharmacyClosureLoaded ? state.request : null;
        return AccountRowCard(
          label: 'طلب إغلاق الحساب'.tr,
          labelColor: AppColors.logoutRed,
          trailing: request == null
              ? Icon(Icons.delete_outline_rounded, size: 22.r, color: AppColors.logoutRed)
              : Text(_statusLabel(request.status), style: AppTextStyles.settingsMutedText),
          height: 58,
          radius: 12,
          onTap: () => _onTap(context, request),
        );
      },
    );
  }
}
