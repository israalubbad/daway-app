import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theming/app_colors.dart';
import '../theming/app_text_styles.dart';
import 'app_bottom_sheet.dart';
import 'app_text_field.dart';

/// The bottom sheet that asks for the last confirmation before an account is
/// deleted (a patient) or its closure is requested (a pharmacy), with an
/// optional reason. Purely presentational: the caller owns the request, and
/// feeds back [isSubmitting] and [errorMessage] while it runs.
class AccountClosureSheet extends StatefulWidget {
  final String title;
  final String message;
  final String confirmLabel;

  /// Sent as the reason the user typed, or an empty string when they did not.
  final ValueChanged<String> onConfirm;

  /// A request is in flight: the buttons are off and the confirm one spins.
  final bool isSubmitting;

  /// Why the last try failed, shown above the buttons.
  final String? errorMessage;

  const AccountClosureSheet({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.onConfirm,
    this.isSubmitting = false,
    this.errorMessage,
  });

  @override
  State<AccountClosureSheet> createState() => _AccountClosureSheetState();
}

class _AccountClosureSheetState extends State<AccountClosureSheet> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: AppBottomSheet(
        padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 32.h),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: _WarningIconCircle()),
              SizedBox(height: 20.h),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: AppTextStyles.confirmSheetTitle,
              ),
              SizedBox(height: 12.h),
              Text(
                widget.message,
                textAlign: TextAlign.center,
                style: AppTextStyles.confirmSheetMessage,
              ),
              SizedBox(height: 20.h),
              AppTextField(
                controller: _reasonController,
                hintText: 'السبب (اختياري)',
                maxLines: 3,
                readOnly: widget.isSubmitting,
              ),
              if (widget.errorMessage != null) ...[
                SizedBox(height: 12.h),
                Text(
                  widget.errorMessage!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.confirmSheetMessage.copyWith(color: AppColors.logoutRed),
                ),
              ],
              SizedBox(height: 20.h),
              SizedBox(
                height: 56.h,
                child: ElevatedButton(
                  onPressed: widget.isSubmitting
                      ? null
                      : () => widget.onConfirm(_reasonController.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.logoutRed,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.logoutRed.withValues(alpha: 0.6),
                    disabledForegroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                  ),
                  child: widget.isSubmitting
                      ? SizedBox(
                          width: 24.r,
                          height: 24.r,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(widget.confirmLabel, style: AppTextStyles.sheetButtonLabel),
                ),
              ),
              SizedBox(height: 12.h),
              SizedBox(
                height: 58.h,
                child: OutlinedButton(
                  onPressed: widget.isSubmitting ? null : () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.sheetTitleText,
                    side: const BorderSide(color: AppColors.sheetOutlineBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                  ),
                  child: Text('إلغاء', style: AppTextStyles.sheetButtonLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WarningIconCircle extends StatelessWidget {
  const _WarningIconCircle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68.r,
      height: 68.r,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: AppColors.logoutRedTint, shape: BoxShape.circle),
      child: Icon(Icons.delete_outline_rounded, size: 30.r, color: AppColors.logoutRed),
    );
  }
}
