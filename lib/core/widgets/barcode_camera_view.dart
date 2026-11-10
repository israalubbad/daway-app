import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../theming/app_colors.dart';
import '../theming/app_fonts.dart';

/// The product barcode kinds: EAN-13, EAN-8, UPC-A, UPC-E, GTIN-14, Code 128.
const productBarcodeFormats = [
  BarcodeFormat.ean13,
  BarcodeFormat.ean8,
  BarcodeFormat.upcA,
  BarcodeFormat.upcE,
  BarcodeFormat.itf14,
  BarcodeFormat.code128,
];

/// A full-screen camera that reports every code of [formats] it reads to
/// [onCode], with a frame to aim with, a back button and a flashlight button.
/// What to tell the user sits at the bottom as [hint], with [footer] under it.
///
/// A controller made here is not paused or resumed by the plugin, so this view
/// stops the camera when the app is inactive and starts it again on return;
/// without that the preview stays black after the app was in the background.
class BarcodeCameraView extends StatefulWidget {
  final List<BarcodeFormat> formats;
  final ValueChanged<String> onCode;
  final VoidCallback onBack;
  final String hint;
  final Widget? footer;

  const BarcodeCameraView({
    super.key,
    required this.formats,
    required this.onCode,
    required this.onBack,
    required this.hint,
    this.footer,
  });

  @override
  State<BarcodeCameraView> createState() => _BarcodeCameraViewState();
}

class _BarcodeCameraViewState extends State<BarcodeCameraView> with WidgetsBindingObserver {
  late final MobileScannerController _controller = MobileScannerController(
    formats: widget.formats,
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_controller.value.hasCameraPermission) return;
    switch (state) {
      case AppLifecycleState.resumed:
        if (!_controller.value.isRunning) unawaited(_controller.start());
      case AppLifecycleState.inactive:
        unawaited(_controller.stop());
      case AppLifecycleState.detached ||
          AppLifecycleState.hidden ||
          AppLifecycleState.paused:
        break;
    }
  }

  void _onDetect(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final code = barcode.rawValue;
      if (code != null && code.isNotEmpty) {
        widget.onCode(code);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isQr = widget.formats.length == 1 && widget.formats.single == BarcodeFormat.qrCode;
    final frameWidth = 260.r;
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => _CameraError(error: error),
          ),
          Center(
            child: Container(
              width: frameWidth,
              height: isQr ? frameWidth : frameWidth * 0.62,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(16.r),
              child: Row(
                children: [
                  _RoundButton(
                    icon: Icons.arrow_forward_ios_rounded,
                    label: 'رجوع',
                    onTap: widget.onBack,
                  ),
                  const Spacer(),
                  ValueListenableBuilder<MobileScannerState>(
                    valueListenable: _controller,
                    builder: (context, state, _) {
                      final on = state.torchState == TorchState.on;
                      return _RoundButton(
                        icon: on ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                        label: on ? 'إطفاء الفلاش' : 'تشغيل الفلاش',
                        onTap: _controller.toggleTorch,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 24.w,
            right: 24.w,
            bottom: 40.h,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.hint,
                    textAlign: TextAlign.center,
                    style: AppFonts.tajawal(
                      TextStyle(fontSize: 14.sp, color: Colors.white),
                      FontWeight.w500,
                    ),
                  ),
                  if (widget.footer != null) ...[SizedBox(height: 12.h), widget.footer!],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _RoundButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44.r,
          height: 44.r,
          decoration: const BoxDecoration(color: Color(0x66000000), shape: BoxShape.circle),
          child: Icon(icon, size: 22.r, color: Colors.white),
        ),
      ),
    );
  }
}

/// What the camera view says when it cannot start: mostly the missing camera
/// permission.
class _CameraError extends StatelessWidget {
  final MobileScannerException error;

  const _CameraError({required this.error});

  @override
  Widget build(BuildContext context) {
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.no_photography_outlined, size: 48.r, color: AppColors.authInputBorder),
            SizedBox(height: 12.h),
            Text(
              denied
                  ? 'اسمح للتطبيق باستخدام الكاميرا من إعدادات الهاتف لمسح الباركود'
                  : 'تعذر تشغيل الكاميرا',
              textAlign: TextAlign.center,
              style: AppFonts.tajawal(
                TextStyle(fontSize: 14.sp, color: Colors.white),
                FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
