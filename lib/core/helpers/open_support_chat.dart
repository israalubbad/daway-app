import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_constants.dart';
import '../widgets/app_snackbar.dart';

import '../../core/localization/translations.dart';

/// Opens a WhatsApp chat with the support number; if WhatsApp cannot be
/// opened, falls back to the phone dialer with the same number, and says so
/// when neither works.
///
/// The messenger is taken before anything is awaited, so the failure message
/// still shows when the caller's own screen (a drawer, say) has closed by the
/// time the launch fails.
Future<void> openSupportChat(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  final whatsapp = Uri.parse('https://wa.me/${AppConstants.supportWhatsAppNumber}');
  final call = Uri(scheme: 'tel', path: AppConstants.supportPhone);

  // launchUrl throws, rather than answering false, when nothing on the phone
  // can handle the link; each attempt is guarded so the next one still runs.
  for (final (uri, mode) in [
    (whatsapp, LaunchMode.externalApplication),
    (call, LaunchMode.platformDefault),
  ]) {
    try {
      if (await launchUrl(uri, mode: mode)) return;
    } catch (_) {
      // Fall through to the next way of reaching support.
    }
  }
  AppSnackbar.showOn(messenger, 'تعذر فتح واتساب أو الاتصال'.tr);
}
