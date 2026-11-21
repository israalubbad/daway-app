import 'package:flutter/material.dart';

abstract class AppSnackbar {
  static void show(BuildContext context, String message) =>
      showOn(ScaffoldMessenger.of(context), message);

  /// Shows [message] on [messenger] — for code that picked the messenger up
  /// before an await or before its own screen closed, so the message still
  /// appears when its context is gone.
  static void showOn(ScaffoldMessengerState messenger, String message) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
