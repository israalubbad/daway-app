import 'package:flutter/widgets.dart';

extension TextControllerSync on TextEditingController {
  /// Makes the text [value] with the cursor at its end, unless it already is:
  /// for a field whose cubit owns the value, so a state change reaches the field
  /// without resetting the cursor the user is typing at.
  void syncText(String value) {
    if (text == value) return;
    text = value;
    selection = TextSelection.collapsed(offset: value.length);
  }
}
