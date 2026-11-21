import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/helpers/digits_only_formatter.dart';
import '../../../../core/theming/app_colors.dart';
import '../../../../core/theming/app_text_styles.dart';
import '../../../../core/widgets/app_custom_button.dart';
import '../../../../core/widgets/birth_date_field.dart';
import '../cubit/patient_auth_cubit.dart';
import '../cubit/patient_auth_state.dart';
import '../screens/privacy_policy_screen.dart';
import '../screens/terms_screen.dart';

import '../../../../core/localization/translations.dart';
import '../../../../core/theming/auth_field_decoration.dart';

class SignUpForm extends StatefulWidget {
  const SignUpForm({super.key});

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    final cubit = context.read<PatientAuthCubit>();
    cubit.nameChanged(_nameController.text.trim());
    cubit.phoneChanged(_phoneController.text);
    cubit.sendOtp();
  }

  /// Rendered as an atomic [WidgetSpan] (not a plain [TextSpan]) so the
  /// two-word phrase always wraps as a whole instead of splitting across
  /// lines mid-phrase. The underline is a manually-drawn bottom border
  /// (rather than [TextDecoration.underline]) so it sits a couple of
  /// pixels below the text instead of hugging the descenders.
  WidgetSpan _consentLink(String text, VoidCallback onTap) {
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.only(bottom: 2.h),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.authTextPrimary, width: 1),
            ),
          ),
          child: Text(text, style: AppTextStyles.authConsentLink),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('اسمك كامل'.tr, style: AppTextStyles.authFieldLabel, textAlign: TextAlign.start),
          SizedBox(height: 8.h),
          TextFormField(
            controller: _nameController,
            textAlign: TextAlign.start,
            style: TextStyle(fontSize: 16.sp, color: AppColors.authTextPrimary),
            validator: (value) =>
                (value == null || value.trim().isEmpty) ? 'الرجاء إدخال اسمك الكامل'.tr : null,
            decoration: authFieldDecoration(),
          ),

          SizedBox(height: 16.h),

          Text('تاريخ الميلاد'.tr, style: AppTextStyles.authFieldLabel, textAlign: TextAlign.start),
          SizedBox(height: 8.h),
          FormField<String>(
            initialValue: context.read<PatientAuthCubit>().state.birthDate,
            validator: (value) =>
                (value == null || value.isEmpty) ? 'الرجاء اختيار تاريخ ميلادك'.tr : null,
            builder: (field) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BlocBuilder<PatientAuthCubit, PatientAuthState>(
                    buildWhen: (previous, current) => previous.birthDate != current.birthDate,
                    builder: (context, state) => BirthDateField(
                      birthDate: state.birthDate,
                      enabled: true,
                      onChanged: (value) {
                        context.read<PatientAuthCubit>().birthDateChanged(value);
                        field.didChange(value);
                      },
                    ),
                  ),
                  if (field.hasError)
                    Padding(
                      padding: EdgeInsets.only(top: 8.h),
                      child: Text(
                        field.errorText!,
                        style: AppTextStyles.authFieldError,
                        textAlign: TextAlign.start,
                      ),
                    ),
                ],
              );
            },
          ),

          SizedBox(height: 16.h),

          Text('رقم هاتفك'.tr, style: AppTextStyles.authFieldLabel, textAlign: TextAlign.start),
          SizedBox(height: 8.h),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.number,
            textDirection: TextDirection.ltr,
            inputFormatters: [DigitsOnlyFormatter()],
            style: TextStyle(fontSize: 16.sp, color: AppColors.authTextPrimary),
            validator: (value) =>
                (value == null || value.trim().isEmpty) ? 'الرجاء إدخال رقم الهاتف'.tr : null,
            decoration: authFieldDecoration(),
          ),

          BlocBuilder<PatientAuthCubit, PatientAuthState>(
            buildWhen: (previous, current) => previous.errorMessage != current.errorMessage,
            builder: (context, state) {
              if (state.errorMessage == null) return const SizedBox.shrink();
              return Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: Text(
                  state.errorMessage!,
                  style: AppTextStyles.authFieldError,
                  textAlign: TextAlign.start,
                ),
              );
            },
          ),

          SizedBox(height: 24.h),

          BlocBuilder<PatientAuthCubit, PatientAuthState>(
            buildWhen: (previous, current) => previous.isSendingOtp != current.isSendingOtp,
            builder: (context, state) {
              return AppCustomButton(
                text: 'التالي'.tr,
                backgroundColor: AppColors.mainTeal,
                isLoading: state.isSendingOtp,
                onPressed: () => _submit(context),
              );
            },
          ),

          SizedBox(height: 16.h),

          Text.rich(
            TextSpan(
              style: AppTextStyles.authConsentText,
              children: [
                TextSpan(text: 'بالضغط على '.tr),
                TextSpan(text: 'التالي'.tr, style: AppTextStyles.authConsentLink),
                TextSpan(text: ' أنت توافق على '.tr),
                _consentLink(
                  'الشروط والأحكام'.tr,
                  () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const TermsScreen()),
                  ),
                ),
                TextSpan(text: ' و '.tr),
                _consentLink(
                  'سياسة الخصوصية'.tr,
                  () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.start,
          ),
        ],
      ),
    );
  }
}
