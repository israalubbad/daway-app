import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'app.dart';
import 'core/di/dependency_injection.dart';
import 'core/routing/app_router.dart';
import 'core/routing/initial_route_resolver.dart';
import 'core/services/notification_service.dart';
import 'core/services/push_notification_service.dart';
import 'core/theming/app_fonts.dart';
import 'features/auth/domain/usecases/get_session_usecase.dart';

// Runs in its own isolate when a push arrives with the app in the background
// or killed, so it has to be top-level and initialise Firebase itself.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  // No time / battery / signal strip at the top of the app: only the system
  // navigation bar stays. (Swiping down from the top still shows it briefly.)
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [SystemUiOverlay.bottom],
  );
  AppFonts.preload();

  // Config comes from google-services.json / GoogleService-Info.plist.
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await dotenv.load(fileName: '.env');
  await setupGetIt();
  await NotificationService.init();
  await getIt<PushNotificationService>().init();

  final initialRoute =
      await InitialRouteResolver(getIt<GetSessionUseCase>()).resolve();

  runApp(DawayApp(appRouter: AppRouter(), initialRoute: initialRoute));

  WidgetsBinding.instance.addPostFrameCallback((_) {
    FlutterNativeSplash.remove();
  });
}
