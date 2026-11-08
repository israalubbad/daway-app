import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/theming/app_colors.dart';
import '../helpers/accounting_styles.dart';

/// A full-screen camera that reads one barcode and hands it back (EAN-13,
/// EAN-8, UPC-A, UPC-E, GTIN-14 and Code 128). Opened from the new-invoice
/// screen's scan button; pops with the code, or with nothing when the user
/// goes back.
class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  /// Opens the camera; completes with the scanned code, or null.
  static Future<String?> scan(BuildContext context) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
  }

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with WidgetsBindingObserver {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.itf14,
      BarcodeFormat.code128,
    ],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  /// The camera keeps reporting the same code until the screen is gone: only
  /// the first one is taken.
  bool _handled = false;

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

  /// A controller made by the screen is not paused or resumed by the plugin:
  /// without this the preview stays black after the app was in the background.
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
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final code = barcode.rawValue;
      if (code != null && code.isNotEmpty) {
        _handled = true;
        Navigator.of(context).pop(code);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final frame = 260.r;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => _ScannerError(error: error),
          ),
          // A frame to aim with.
          Center(
            child: Container(
              width: frame,
              height: frame * 0.62,
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
                    onTap: () => Navigator.of(context).pop(),
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
            bottom: 48.h,
            child: Text(
              'وجّه الكاميرا نحو الباركود',
              textAlign: TextAlign.center,
              style: AccountingStyles.body.copyWith(color: Colors.white),
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
class _ScannerError extends StatelessWidget {
  final MobileScannerException error;

  const _ScannerError({required this.error});

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
              style: AccountingStyles.body.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
