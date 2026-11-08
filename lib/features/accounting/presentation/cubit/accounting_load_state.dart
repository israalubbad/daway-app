/// What a loading screen holds: still loading, failed (with the message to
/// show), or its [data].
sealed class AccountingLoad<T> {
  const AccountingLoad();
}

class AccountingLoading<T> extends AccountingLoad<T> {
  const AccountingLoading();
}

class AccountingLoadFailure<T> extends AccountingLoad<T> {
  final String message;

  const AccountingLoadFailure(this.message);
}

class AccountingLoaded<T> extends AccountingLoad<T> {
  final T data;

  const AccountingLoaded(this.data);
}
