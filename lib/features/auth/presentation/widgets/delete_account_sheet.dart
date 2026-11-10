import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/account_closure_sheet.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../cubit/account_closure_cubit.dart';
import '../cubit/account_closure_state.dart';

/// The patient's "delete my account" confirmation. It stays open while the
/// request runs and shows why it failed; on success the screen underneath
/// ends the session and replaces every route, which takes this sheet with it.
class DeleteAccountSheet extends StatelessWidget {
  final AccountClosureCubit cubit;

  const DeleteAccountSheet({super.key, required this.cubit});

  static Future<void> show(BuildContext context, AccountClosureCubit cubit) {
    // An error from an earlier try belongs to that try, not to this opening.
    cubit.clearError();
    return AppBottomSheet.show<void>(context, builder: (_) => DeleteAccountSheet(cubit: cubit));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccountClosureCubit, AccountClosureState>(
      bloc: cubit,
      builder: (context, state) => AccountClosureSheet(
        title: 'حذف الحساب نهائياً؟',
        message: 'سيتم حذف حسابك وبياناتك ولا يمكن التراجع عن ذلك. '
            'لن تتمكن من الدخول بهذا الرقم مرة أخرى.',
        confirmLabel: 'حذف حسابي',
        isSubmitting: state is AccountClosureSubmitting,
        errorMessage: state is AccountClosureIdle ? state.errorMessage : null,
        onConfirm: (reason) => cubit.deleteAccount(reason: reason),
      ),
    );
  }
}
