import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/di/dependency_injection.dart';
import '../../../../core/theming/app_colors.dart';
import '../../../../core/theming/app_fonts.dart';
import '../../../../core/widgets/app_custom_button.dart';
import '../../../../core/widgets/barcode_camera_view.dart';
import '../cubit/phone_scanner_cubit.dart';
import '../cubit/phone_scanner_state.dart';

import '../../../../core/localization/translations.dart';

/// "المسح بالهاتف": the phone as the web sales screen's barcode scanner. First
/// the camera reads the QR code in the web screen's "وصل هاتفك" window to join
/// its scan session; then every barcode it reads is sent to that screen.
class PhoneScannerScreen extends StatelessWidget {
  const PhoneScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PhoneScannerCubit>(),
      child: const _PhoneScannerView(),
    );
  }
}

class _PhoneScannerView extends StatelessWidget {
  const _PhoneScannerView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PhoneScannerCubit>();
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocBuilder<PhoneScannerCubit, PhoneScannerState>(
        builder: (context, state) {
          void back() => Navigator.of(context).pop();
          return switch (state.phase) {
            // A different camera view per phase (the QR code, then product
            // barcodes): switching drops the first and starts the second.
            PhoneScannerPhase.pairing => BarcodeCameraView(
              key: const ValueKey('pairing-camera'),
              formats: const [BarcodeFormat.qrCode],
              onCode: cubit.qrDetected,
              onBack: back,
              hint: 'امسح رمز QR الظاهر في نافذة «وصل هاتفك» على شاشة البيع في الموقع'.tr,
              footer: _StatusLine(state: state),
            ),
            PhoneScannerPhase.scanning => BarcodeCameraView(
              key: const ValueKey('scanning-camera'),
              formats: productBarcodeFormats,
              onCode: cubit.barcodeDetected,
              onBack: back,
              hint: 'وجّه الكاميرا نحو باركود الدواء، وسيصل إلى شاشة البيع'.tr,
              footer: _StatusLine(state: state, showCount: true),
            ),
            PhoneScannerPhase.ended => _EndedView(
              message: state.message ?? 'انتهت جلسة المسح'.tr,
              onRestart: cubit.restart,
              onBack: back,
            ),
          };
        },
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  final PhoneScannerState state;
  final bool showCount;

  const _StatusLine({required this.state, this.showCount = false});

  @override
  Widget build(BuildContext context) {
    if (state.isBusy) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      );
    }
    final message = state.message;
    if (message == null) return const SizedBox.shrink();
    final color = state.isError ? const Color(0xFFFFB4AB) : const Color(0xFFB7F5C8);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppFonts.tajawal(TextStyle(fontSize: 14.sp, color: color), FontWeight.w700),
        ),
        if (showCount && state.lastBarcode != null)
          Padding(
            padding: EdgeInsets.only(top: 4.h),
            child: Text(
              '${state.lastBarcode} · ${state.sentCount}',
              textDirection: TextDirection.ltr,
              style: AppFonts.tajawal(
                TextStyle(fontSize: 12.sp, color: Colors.white70),
                FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}

class _EndedView extends StatelessWidget {
  final String message;
  final VoidCallback onRestart;
  final VoidCallback onBack;

  const _EndedView({required this.message, required this.onRestart, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.link_off_rounded, size: 56.r, color: AppColors.authInputBorder),
            SizedBox(height: 16.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppFonts.tajawal(
                TextStyle(fontSize: 16.sp, color: Colors.white),
                FontWeight.w700,
              ),
            ),
            SizedBox(height: 24.h),
            AppCustomButton(text: 'اقتران جديد'.tr, onPressed: onRestart),
            SizedBox(height: 12.h),
            AppCustomButton(
              text: 'رجوع'.tr,
              backgroundColor: Colors.transparent,
              borderColor: Colors.white54,
              textColor: Colors.white,
              onPressed: onBack,
            ),
          ],
        ),
      ),
    );
  }
}
