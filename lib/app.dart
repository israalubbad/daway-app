import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'core/routing/app_navigator.dart';
import 'core/routing/app_router.dart';
import 'core/theming/app_theme.dart';

class DawayApp extends StatelessWidget {
  final AppRouter appRouter;
  final String initialRoute;

  const DawayApp({
    super.key,
    required this.appRouter,
    required this.initialRoute,
  });

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(440, 956),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          navigatorKey: appNavigatorKey,
          title: 'Dawak',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          onGenerateRoute: appRouter.generateRoute,
          initialRoute: initialRoute,
          // Flutter would also build a route for "/" under the initial one, and
          // the router answers it with its "No route defined" page: going back
          // from the home screen (or any `pushAndRemoveUntil(..., isFirst)`)
          // landed on it. Only the initial route belongs on the stack.
          onGenerateInitialRoutes: (name) => [
            appRouter.generateRoute(RouteSettings(name: name))!,
          ],
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        );
      },
    );
  }
}