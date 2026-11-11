import 'package:flutter/widgets.dart';

/// Draws [child] mirrored when the text runs left-to-right. The app's
/// directional pictures (back and "more" arrows) are drawn for right-to-left,
/// and a picture, unlike a `Row`, does not turn around by itself: in English
/// the back arrow must point left and a "view all" arrow right.
class MirrorWhenLtr extends StatelessWidget {
  final Widget child;

  const MirrorWhenLtr({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (Directionality.of(context) == TextDirection.rtl) return child;
    return Transform.flip(flipX: true, child: child);
  }
}
