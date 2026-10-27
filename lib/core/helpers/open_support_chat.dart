import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_constants.dart';
import '../widgets/app_snackbar.dart';

/// Opens a WhatsApp chat with the support number; if WhatsApp cannot be
/// opened, falls back to the phone dialer with the same number.
Future<void> openSupportChat(BuildContext context) async {
  final whatsapp = Uri.parse('https://wa.me/${AppConstants.supportWhatsAppNumber}');
  if (await launchUrl(whatsapp, mode: LaunchMode.externalApplication)) return;

  final call = Uri(scheme: 'tel', path: AppConstants.supportPhone);
  if (await launchUrl(call)) return;

  if (context.mounted) AppSnackbar.show(context, 'تعذر فتح واتساب أو الاتصال');
}
