import 'package:flutter/widgets.dart';

/// The root navigator, reachable without a [BuildContext] — used by code that
/// reacts to app-wide events (an expired session) rather than to a screen.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
