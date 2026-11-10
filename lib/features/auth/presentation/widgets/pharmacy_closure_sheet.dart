import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/account_closure_sheet.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../cubit/pharmacy_closure_cubit.dart';
import '../cubit/pharmacy_closure_state.dart';

/// The pharmacy's "ask to close my account" confirmation. A pharmacy cannot
/// delete itself — the admin reviews the request — so the wording says so, and
/// the sheet closes by itself once the request has been sent.
class PharmacyClosureSheet extends StatelessWidget {
  final PharmacyClosureCubit cubit;

  const PharmacyClosureSheet({super.key, required this.cubit});

  static Future<void> show(BuildContext context, PharmacyClosureCubit cubit) {
    // An error from an earlier try belongs to that try, not to this opening.
    cubit.clearError();
    return AppBottomSheet.show<void>(context, builder: (_) => PharmacyClosureSheet(cubit: cubit));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PharmacyClosureCubit, PharmacyClosureState>(
      bloc: cubit,
      listenWhen: closureRequestJustSent,
      listener: (context, state) => Navigator.of(context).pop(),
      builder: (context, state) {
        final loaded = state is PharmacyClosureLoaded ? state : null;
        return AccountClosureSheet(
          title: 'طلب إغلاق الحساب؟',
          message: 'سيصل طلبك إلى إدارة التطبيق لمراجعته، ويبقى حسابك يعمل '
              'حتى يتم قبوله. بعد الإغلاق لا يمكن استرجاع الحساب.',
          confirmLabel: 'إرسال الطلب',
          isSubmitting: loaded?.isSubmitting ?? false,
          errorMessage: loaded?.errorMessage,
          onConfirm: (reason) => cubit.submit(reason: reason),
        );
      },
    );
  }
}
