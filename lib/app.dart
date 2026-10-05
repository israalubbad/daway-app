import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
          title: 'Dawak',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          onGenerateRoute: appRouter.generateRoute,
          initialRoute: initialRoute,
          // By default MaterialApp first pushes a route for "/" and then the
          // initial route on top of it; the router has no "/" page, so that
          // bottom route is the "No route defined for /" placeholder and the
          // phone's back button from the home screen landed on it. Build only
          // the real initial route, so back from it leaves the app.
          onGenerateInitialRoutes: (name) => [
            ?appRouter.generateRoute(RouteSettings(name: name)),
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