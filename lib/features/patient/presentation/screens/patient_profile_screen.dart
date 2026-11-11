import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theming/app_colors.dart';
import '../../../../core/theming/app_text_styles.dart';
import '../../../../core/widgets/app_custom_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/profile_load_error.dart';
import '../cubit/patient_profile_cubit.dart';
import '../cubit/patient_profile_state.dart';
import '../widgets/patient_profile_avatar.dart';
import '../widgets/patient_sub_screen_header.dart';

import '../../../../core/localization/translations.dart';
/// "معلومات الحساب": the name and birth date are inputs you simply tap and

/// change (no "edit" mode to enter first), the phone number is shown locked,
/// and "حفظ التعديلات" only lights up once something has changed.
class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  Future<void> _pickBirthDate(BuildContext context, String? current) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(current ?? '') ?? DateTime(now.year - 20),
      firstDate: DateTime(now.year - 120),
      lastDate: now,
    );
    if (picked == null || !context.mounted) return;
    final year = picked.year.toString().padLeft(4, '0');
    final month = picked.month.toString().padLeft(2, '0');
    final day = picked.day.toString().padLeft(2, '0');
    context.read<PatientProfileCubit>().birthDateChanged('$year-$month-$day');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<PatientProfileCubit, PatientProfileState>(
          listenWhen: (previous, current) =>
              current is PatientProfileLoaded &&
              current.saveError != null &&
              (previous is! PatientProfileLoaded || previous.saveError != current.saveError),
          listener: (context, state) {
            if (state is PatientProfileLoaded && state.saveError != null) {
              AppSnackbar.show(context, state.saveError!);
            }
          },
          builder: (context, state) {
            return switch (state) {
              PatientProfileLoading() => const Center(child: CircularProgressIndicator()),
              PatientProfileLoadFailure(:final message) => ProfileLoadError(
                  message: message,
                  onRetry: () => context.read<PatientProfileCubit>().load(),
                ),
              PatientProfileLoaded() => _buildLoaded(context, state),
            };
          },
        ),
      ),
    );
  }

  Widget _buildLoaded(BuildContext context, PatientProfileLoaded state) {
    final cubit = context.read<PatientProfileCubit>();
    final canSave = state.canSave && state.hasChanges && !state.isSaving;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PatientSubScreenHeader(
            title: 'معلومات الحساب'.tr,
            description: 'اضغط على أي حقل لتغييره، ثم احفظ التعديلات.'.tr,
          ),
          SizedBox(height: 32.h),
          Center(
            child: PatientProfileAvatar(
              name: state.name,
              avatarLocalPath: state.avatarLocalPath,
              avatarUrl: state.avatarUrl,
              avatarVersion: state.avatarVersion,
              isUploading: state.isUploadingAvatar,
              errorMessage: state.avatarError,
              onImagePicked: (file) => cubit.avatarSelected(file),
            ),
          ),
          SizedBox(height: 32.h),
          Text('الاسم'.tr, textAlign: TextAlign.start, style: AppTextStyles.profileFieldLabel),
          SizedBox(height: 8.h),
          _FieldBox(
            icon: Icons.edit_outlined,
            // Re-created (and so reset to the saved name) whenever the saved
            // profile changes, e.g. after saving; typing never rebuilds it.
            child: _NameInput(
              key: ValueKey(state.profile),
              initialName: state.name,
              onChanged: cubit.nameChanged,
            ),
          ),
          if (state.name.trim().isEmpty)
            Padding(
              padding: EdgeInsets.only(top: 6.h),
              child: Text(
                'الاسم مطلوب'.tr,
                textAlign: TextAlign.start,
                style: AppTextStyles.authFieldError,
              ),
            ),
          SizedBox(height: 24.h),
          Text('تاريخ الميلاد'.tr, textAlign: TextAlign.start, style: AppTextStyles.profileFieldLabel),
          SizedBox(height: 8.h),
          _FieldBox(
            icon: Icons.calendar_today_outlined,
            onTap: () => _pickBirthDate(context, state.birthDate),
            child: Text(
              state.birthDate ?? 'اختر تاريخ ميلادك'.tr,
              textAlign: TextAlign.start,
              style: AppTextStyles.profileFieldValue.copyWith(
                color: state.birthDate == null ? AppColors.grey : null,
              ),
            ),
          ),
          SizedBox(height: 24.h),
          Text('رقم الهاتف'.tr, textAlign: TextAlign.start, style: AppTextStyles.profileFieldLabel),
          SizedBox(height: 8.h),
          _FieldBox(
            icon: Icons.lock_outline,
            locked: true,
            child: Text(
              state.profile.phone,
              textAlign: TextAlign.start,
              style: AppTextStyles.profileFieldValue,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 6.h),
            child: Text(
              'رقم الهاتف مرتبط بحسابك ولا يمكن تغييره من هنا.'.tr,
              textAlign: TextAlign.start,
              style: TextStyle(fontSize: 12.sp, color: AppColors.grey),
            ),
          ),
          SizedBox(height: 40.h),
          AppCustomButton(
            text: 'حفظ التعديلات'.tr,
            isLoading: state.isSaving,
            backgroundColor: canSave ? AppColors.mainTeal : AppColors.borderGrey,
            onPressed: canSave ? cubit.save : () {},
          ),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }
}

/// A bordered field: the value on the right, and a small icon at the left that
/// says what the box does — a pencil (type here), a calendar (pick a date) or
/// a lock (read only).
class _FieldBox extends StatelessWidget {
  final Widget child;
  final IconData icon;
  final VoidCallback? onTap;
  final bool locked;

  const _FieldBox({
    required this.child,
    required this.icon,
    this.onTap,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 62.h,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          color: locked ? AppColors.permissionIconBg : Colors.white,
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            Expanded(child: child),
            SizedBox(width: 8.w),
            Icon(icon, size: 20.sp, color: locked ? AppColors.grey : AppColors.mainTeal),
          ],
        ),
      ),
    );
  }
}

class _NameInput extends StatefulWidget {
  final String initialName;
  final ValueChanged<String> onChanged;

  const _NameInput({super.key, required this.initialName, required this.onChanged});

  @override
  State<_NameInput> createState() => _NameInputState();
}

class _NameInputState extends State<_NameInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      textAlign: TextAlign.start,
      textInputAction: TextInputAction.done,
      onChanged: widget.onChanged,
      style: AppTextStyles.profileFieldValue,
      decoration: InputDecoration(
        isDense: true,
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        hintText: 'اكتب اسمك'.tr,
        hintStyle: AppTextStyles.profileFieldValue.copyWith(color: AppColors.grey),
      ),
    );
  }
}
