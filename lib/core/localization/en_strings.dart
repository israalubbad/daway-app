import 'en/en_accounting.dart';
import 'en/en_auth.dart';
import 'en/en_chat.dart';
import 'en/en_lib.dart';
import 'en/en_manual.dart';
import 'en/en_onboarding.dart';
import 'en/en_patient.dart';
import 'en/en_pharmacy.dart';
import 'en/en_scanner.dart';

/// English for the app's Arabic texts, keyed by the Arabic text itself.
/// A text missing here shows in Arabic (see `TranslateText.tr`).
final Map<String, String> enStrings = {
  ...enLib,
  ...enChat,
  ...enOnboarding,
  ...enScanner,
  ...enAuth,
  ...enAccounting,
  ...enPharmacy,
  ...enPatient,
  ...enManual,
};
