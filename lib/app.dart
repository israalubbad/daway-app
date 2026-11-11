import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'core/di/dependency_injection.dart';
import 'core/routing/app_navigator.dart';
import 'core/routing/app_router.dart';
import 'core/theming/app_theme.dart';
import 'features/localization/domain/entities/app_language.dart';
import 'features/localization/presentation/cubit/language_cubit.dart';

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
        return BlocConsumer<LanguageCubit, AppLanguage>(
          bloc: getIt<LanguageCubit>(),
          // The texts are looked up when a widget builds, and a widget that was
          // built in the old language would keep it: once the new locale is in,
          // every element of the tree is rebuilt (state and scroll positions
          // are kept, unlike with a new key).
          listener: (context, language) => WidgetsBinding.instance.addPostFrameCallback(
            (_) => _rebuildAll(WidgetsBinding.instance.rootElement),
          ),
          builder: (context, language) => MaterialApp(
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
            locale: Locale(language.code),
            supportedLocales: const [Locale('ar'), Locale('en')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
          ),
        );
      },
    );
  }

  static void _rebuildAll(Element? element) {
    if (element == null) return;
    element.markNeedsBuild();
    element.visitChildren(_rebuildAll);
  }
}
