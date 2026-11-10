import 'package:flutter/material.dart';

import '../../../../core/widgets/barcode_camera_view.dart';

/// A full-screen camera that reads one product barcode and hands it back.
/// Opened from the new-invoice screen's scan button; pops with the code, or
/// with nothing when the user goes back.
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

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  /// The camera keeps reporting the same code until the screen is gone: only
  /// the first one is taken.
  bool _handled = false;

  void _onCode(String code) {
    if (_handled) return;
    _handled = true;
    Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BarcodeCameraView(
        formats: productBarcodeFormats,
        onCode: _onCode,
        onBack: () => Navigator.of(context).pop(),
        hint: 'وجّه الكاميرا نحو الباركود',
      ),
    );
  }
}
