import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/helpers/open_location_picker.dart';
import '../../../../core/theming/app_colors.dart';
import '../../../../core/theming/app_text_styles.dart';
import '../../../../core/widgets/app_custom_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/profile_field_row.dart';
import '../../../../core/widgets/profile_load_error.dart';
import '../../../patient/presentation/widgets/patient_profile_avatar.dart';
import '../../../patient/presentation/widgets/patient_sub_screen_header.dart';
import '../cubit/pharmacy_profile_cubit.dart';
import '../cubit/pharmacy_profile_state.dart';
import '../helpers/working_hours_format.dart';
import '../widgets/change_password_sheet.dart';
import '../widgets/working_hours_dialog.dart';

import '../../../../core/localization/translations.dart';

/// "معلومات الحساب": the pharmacy's logo, name, phone, address, working hours
/// and password, each on a row with a "تعديل" chip, and one save button.
///
/// Expects the shell's [PharmacyProfileCubit] above it. The edits live in that
/// shared cubit until saved, so leaving the screen discards them.
///
/// The phone number is edited in place and saved with the rest of the profile;
/// the password opens its own sheet and is sent right away.
class PharmacyAccountInfoScreen extends StatefulWidget {
  const PharmacyAccountInfoScreen({super.key});

  @override
  State<PharmacyAccountInfoScreen> createState() =>
      _PharmacyAccountInfoScreenState();
}

class _PharmacyAccountInfoScreenState extends State<PharmacyAccountInfoScreen> {
  late final TextEditingController _nameController;
  final FocusNode _nameFocus = FocusNode();
  bool _editingName = false;
  late final TextEditingController _phoneController;
  final FocusNode _phoneFocus = FocusNode();
  bool _editingPhone = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocus.dispose();
    _phoneController.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  // The field is filled when editing starts, from the profile as it is by then:
  // the screen can open before the profile has loaded.
  void _editPhone(PharmacyProfileLoaded state) {
    _phoneController.text = state.phone;
    setState(() => _editingPhone = true);
    _phoneFocus.requestFocus();
  }

  void _editName(PharmacyProfileLoaded state) {
    _nameController.text = state.name;
    setState(() => _editingName = true);
    _nameFocus.requestFocus();
  }

  Future<void> _editAddress(PharmacyProfileLoaded state) async {
    final picked = await openLocationPicker(
      context,
      latitude: state.latitude,
      longitude: state.longitude,
      address: state.address,
    );
    if (picked == null || !mounted) return;
    context.read<PharmacyProfileCubit>().locationSelected(picked);
  }

  Future<void> _editWorkingHours(PharmacyProfileLoaded state) async {
    final edited = await WorkingHoursDialog.show(
      context,
      initial: state.workingHours,
    );
    if (edited == null || !mounted) return;
    context.read<PharmacyProfileCubit>().workingHoursReplaced(edited);
  }

  String _addressText(PharmacyProfileLoaded state) {
    final address = state.address;
    if (address != null && address.isNotEmpty) return address;
    if (state.hasLocation) {
      return '${state.latitude!.toStringAsFixed(5)}, ${state.longitude!.toStringAsFixed(5)}';
    }
    return 'اختر موقعك على الخريطة'.tr;
  }

  @override
  Widget build(BuildContext context) {
    // Leaving the screen — the back chip or the system back — drops whatever
    // was edited and not saved, so the next visit starts from the saved profile.
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) context.read<PharmacyProfileCubit>().discardEdits();
      },
      child: Scaffold(
        body: SafeArea(
          child: BlocConsumer<PharmacyProfileCubit, PharmacyProfileState>(
            listenWhen: (previous, current) =>
                current is PharmacyProfileLoaded &&
                current.saveError != null &&
                (previous is! PharmacyProfileLoaded ||
                    previous.saveError != current.saveError),
            listener: (context, state) {
              if (state is PharmacyProfileLoaded && state.saveError != null) {
                AppSnackbar.show(context, state.saveError!);
              }
            },
            builder: (context, state) {
              return switch (state) {
                PharmacyProfileLoading() => const Center(
                  child: CircularProgressIndicator(),
                ),
                PharmacyProfileLoadFailure(:final message) => ProfileLoadError(
                  message: message,
                  onRetry: () => context.read<PharmacyProfileCubit>().load(),
                ),
                PharmacyProfileLoaded() => _buildLoaded(context, state),
              };
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoaded(BuildContext context, PharmacyProfileLoaded state) {
    final cubit = context.read<PharmacyProfileCubit>();
    final canSave = state.hasChanges && state.canSave;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PatientSubScreenHeader(
            title: 'معلومات الحساب'.tr,
            description: 'إدارة معلومات صيدليتك وتفاصيلها'.tr,
          ),
          SizedBox(height: 32.h),
          Center(
            child: PatientProfileAvatar(
              name: state.name,
              avatarLocalPath: state.logoLocalPath,
              avatarUrl: state.logoUrl,
              avatarVersion: 0,
              isUploading: state.isUploadingLogo,
              errorMessage: state.logoError,
              onImagePicked: (file) => cubit.logoSelected(file),
            ),
          ),
          SizedBox(height: 16.h),
          Center(
            child: Text(
              state.profile.name,
              style: AppTextStyles.profileFieldLabel,
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 24.h),
          _FieldLabel('الاسم'.tr),
          ProfileFieldRow(
            onEditTap: () => _editName(state),
            child: _editingName
                ? TextField(
                    controller: _nameController,
                    focusNode: _nameFocus,
                    textAlign: TextAlign.start,
                    onChanged: cubit.nameChanged,
                    style: AppTextStyles.profileFieldValue,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  )
                : Text(
                    state.name,
                    textAlign: TextAlign.start,
                    style: AppTextStyles.profileFieldValue,
                  ),
          ),
          SizedBox(height: 24.h),
          _FieldLabel('رقم الهاتف'.tr),
          ProfileFieldRow(
            onEditTap: () => _editPhone(state),
            child: _editingPhone
                ? TextField(
                    controller: _phoneController,
                    focusNode: _phoneFocus,
                    keyboardType: TextInputType.phone,
                    textAlign: TextAlign.start,
                    textDirection: TextDirection.ltr,
                    onChanged: cubit.phoneChanged,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[+\d]')),
                    ],
                    style: AppTextStyles.profileFieldValue,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  )
                : Text(
                    state.phone,
                    textAlign: TextAlign.start,
                    style: AppTextStyles.profileFieldValue,
                  ),
          ),
          if (_editingPhone && !state.hasValidPhone)
            Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: Text(
                'أدخل رقم جوال صحيح'.tr,
                textAlign: TextAlign.start,
                style: AppTextStyles.mutedCaption.copyWith(color: AppColors.error),
              ),
            ),
          SizedBox(height: 24.h),
          _FieldLabel('العنوان'.tr),
          ProfileFieldRow(
            onEditTap: () => _editAddress(state),
            child: Text(
              _addressText(state),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.start,
              style: AppTextStyles.profileFieldValue,
            ),
          ),
          SizedBox(height: 24.h),
          _FieldLabel('ساعات العمل'.tr),
          ProfileFieldRow(
            onEditTap: () => _editWorkingHours(state),
            child: Text(
              summarizeWorkingHours(state.workingHours),
              textAlign: TextAlign.start,
              style: AppTextStyles.profileFieldValue,
            ),
          ),
          SizedBox(height: 24.h),
          _FieldLabel('كلمة المرور'.tr),
          ProfileFieldRow(
            onEditTap: () => ChangePasswordSheet.show(context),
            child: Text(
              '*******',
              textAlign: TextAlign.start,
              style: AppTextStyles.profileFieldValue,
            ),
          ),
          SizedBox(height: 32.h),
          AppCustomButton(
            text: 'حفظ التعديلات'.tr,
            isLoading: state.isSaving,
            backgroundColor: canSave
                ? AppColors.mainTeal
                : AppColors.borderGrey,
            onPressed: canSave ? cubit.save : () {},
          ),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        text,
        textAlign: TextAlign.start,
        style: AppTextStyles.profileFieldLabel,
      ),
    );
  }
}
