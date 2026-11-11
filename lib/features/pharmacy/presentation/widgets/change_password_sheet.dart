import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/di/dependency_injection.dart';
import '../../../../core/theming/app_text_styles.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_custom_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/auth_text_field.dart';
import '../cubit/change_pharmacy_password_cubit.dart';

import '../../../../core/localization/translations.dart';

/// "تعديل كلمة المرور": the current password, the new one and its repeat, in a
/// bottom sheet. Closes by itself, with a confirmation, once the backend
/// accepts the change.
class ChangePasswordSheet extends StatefulWidget {
  const ChangePasswordSheet({super.key});

  static Future<void> show(BuildContext context) {
    return AppBottomSheet.show<void>(
      context,
      builder: (_) => BlocProvider(
        create: (_) => getIt<ChangePharmacyPasswordCubit>(),
        child: const ChangePasswordSheet(),
      ),
    );
  }

  @override
  State<ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<ChangePasswordSheet> {
  late final TextEditingController _current;
  late final TextEditingController _new;
  late final TextEditingController _confirm;

  @override
  void initState() {
    super.initState();
    _current = TextEditingController();
    _new = TextEditingController();
    _confirm = TextEditingController();
  }

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    context.read<ChangePharmacyPasswordCubit>().submit(
      currentPassword: _current.text,
      newPassword: _new.text,
      confirmation: _confirm.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChangePharmacyPasswordCubit, ChangePharmacyPasswordState>(
      listener: (context, state) {
        if (state is ChangePasswordSuccess) {
          AppSnackbar.show(context, 'تم تغيير كلمة المرور'.tr);
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        final message = state is ChangePasswordIdle ? state.message : null;
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: AppBottomSheet(
            padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 24.h),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('تعديل كلمة المرور'.tr, style: AppTextStyles.pharmacyPageSubtitle),
                  SizedBox(height: 16.h),
                  AuthTextField(
                    label: 'كلمة المرور الحالية'.tr,
                    controller: _current,
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                  ),
                  SizedBox(height: 12.h),
                  AuthTextField(
                    label: 'كلمة المرور الجديدة'.tr,
                    controller: _new,
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                  ),
                  SizedBox(height: 12.h),
                  AuthTextField(
                    label: 'تأكيد كلمة المرور الجديدة'.tr,
                    controller: _confirm,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                  ),
                  if (message != null) ...[
                    SizedBox(height: 8.h),
                    Text(message, style: AppTextStyles.errorText),
                  ],
                  SizedBox(height: 20.h),
                  AppCustomButton(
                    text: 'حفظ كلمة المرور'.tr,
                    isLoading: state is ChangePasswordSaving,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
