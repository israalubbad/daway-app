import '../../features/auth/domain/repositories/session_repository.dart';
import '../routing/app_navigator.dart';
import '../routing/routes.dart';
import '../widgets/session_expired_dialog.dart';

/// Reacts to the backend rejecting the stored token: drops the dead session,
/// tells the user, and sends them back to the login entry screen.
class SessionExpiryHandler {
  final SessionRepository _sessionRepository;
  bool _handling = false;

  SessionExpiryHandler(this._sessionRepository);

  Future<void> handle() async {
    // Several requests usually fail together; show the dialog once.
    if (_handling) return;
    _handling = true;
    try {
      // Clear first so a restart while the dialog is open lands on login.
      await _sessionRepository.clearSession();

      final context = appNavigatorKey.currentContext;
      if (context == null || !context.mounted) return;
      await SessionExpiredDialog.show(context);

      appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
        Routes.accountTypeScreen,
        (route) => false,
      );
    } finally {
      _handling = false;
    }
  }
}
