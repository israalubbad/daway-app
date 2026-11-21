/// Where a patient's request to delete their account stands.
sealed class AccountClosureState {
  const AccountClosureState();
}

/// Nothing sent yet (or the last try failed and the user may try again).
class AccountClosureIdle extends AccountClosureState {
  /// Why the last try failed, when it did.
  final String? errorMessage;

  const AccountClosureIdle({this.errorMessage});
}

class AccountClosureSubmitting extends AccountClosureState {
  const AccountClosureSubmitting();
}

/// The account is deleted and the local session ended.
class AccountClosureDone extends AccountClosureState {
  const AccountClosureDone();
}
