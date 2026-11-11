import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theming/app_text_styles.dart';
import '../../../../core/widgets/app_logo.dart';
import '../cubit/patient_auth_cubit.dart';
import '../cubit/patient_auth_state.dart';
import '../widgets/patient_phone_form.dart';
import 'otp_verification_screen.dart';

import '../../../../core/localization/translations.dart';
class PatientAuthScreen extends StatelessWidget {

  const PatientAuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocListener<PatientAuthCubit, PatientAuthState>(
          listenWhen: (previous, current) => !previous.otpSent && current.otpSent,
          listener: (context, state) {
            final cubit = context.read<PatientAuthCubit>();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: cubit,
                  child: const OtpVerificationScreen(),
                ),
              ),
            );
          },
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 32.h),
                const Center(child: AppLogo()),
                SizedBox(height: 32.h),

                Text(
                  'مرحباً بعودتك!'.tr,
                  textAlign: TextAlign.start,
                  style: AppTextStyles.authScreenTitle,
                ),
                SizedBox(height: 8.h),

                Text(
                  'سجّل دخولك برقم هاتفك للوصول إلى حسابك ومتابعة طلباتك بسهولة.'.tr,
                  textAlign: TextAlign.start,
                  style: AppTextStyles.authScreenSubtitle,
                ),
                SizedBox(height: 24.h),

                const PatientPhoneForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}