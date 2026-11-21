import 'package:daway_app/core/widgets/app_back_button.dart';
import 'package:daway_app/core/helpers/api_result.dart';
import 'package:daway_app/features/pharmacy/domain/entities/notification.dart';
import 'package:daway_app/features/pharmacy/domain/repositories/notifications_repository.dart';
import 'package:daway_app/features/pharmacy/domain/usecases/get_notifications_usecase.dart';
import 'package:daway_app/features/pharmacy/domain/usecases/mark_all_notifications_read_usecase.dart';
import 'package:daway_app/features/pharmacy/domain/usecases/mark_notification_read_usecase.dart';
import 'package:daway_app/features/pharmacy/presentation/cubit/notifications_cubit.dart';
import 'package:daway_app/features/pharmacy/presentation/screens/pharmacy_notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../helpers/in_memory_session_repository.dart';

final _unreadLowStock = AppNotification(
  id: 1,
  type: NotificationType.lowStock,
  message: 'تنبيه نقص مخزون دواء Panadol',
  isRead: false,
  createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
);
final _readRating = AppNotification(
  id: 2,
  type: NotificationType.newRating,
  message: 'أضاف مريض تقييمًا جديدًا لصيدلية الشفاء',
  isRead: true,
  createdAt: DateTime.now().subtract(const Duration(hours: 3)),
);

class _FakeNotificationsRepository implements NotificationsRepository {
  int? lastMarkedId;
  int markAllCallCount = 0;

  @override
  Future<ApiResult<NotificationsOverview>> getNotifications({
    required String token,
  }) async {
    return Success(
      NotificationsOverview(
        notifications: [_unreadLowStock, _readRating],
        unreadCount: 1,
      ),
    );
  }

  @override
  Future<ApiResult<void>> markAllAsRead({required String token}) async {
    markAllCallCount++;
    return const Success(null);
  }

  @override
  Future<ApiResult<void>> markAsRead({
    required String token,
    required int notificationId,
  }) async {
    lastMarkedId = notificationId;
    return const Success(null);
  }
}

void main() {
  Future<void> setPhoneViewport(WidgetTester tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  late _FakeNotificationsRepository repository;

  Widget buildTestableScreen() {
    repository = _FakeNotificationsRepository();
    final sessionRepository = InMemorySessionRepository.pharmacy();
    final cubit = NotificationsCubit(
      GetNotificationsUseCase(repository, sessionRepository),
      MarkAllNotificationsReadUseCase(repository, sessionRepository),
      MarkNotificationReadUseCase(repository, sessionRepository),
    );
    addTearDown(cubit.close);

    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, child) => MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: const PharmacyNotificationsScreen(),
        ),
      ),
    );
  }

  testWidgets('shows every notification and the mark-all-as-read link', (
    tester,
  ) async {
    await setPhoneViewport(tester);

    await tester.pumpWidget(buildTestableScreen());
    await tester.pumpAndSettle();

    expect(find.text('تحديد الكل كمقروء'), findsOneWidget);
    expect(find.text('تنبيه نقص مخزون دواء Panadol'), findsOneWidget);
    expect(find.text('أضاف مريض تقييمًا جديدًا لصيدلية الشفاء'), findsOneWidget);
    expect(find.text('دواء نافد من المخزون'), findsNothing);
    expect(find.text('مخزون منخفض'), findsOneWidget);
    expect(find.text('تقييم جديد'), findsOneWidget);
  });

  testWidgets('tapping "تحديد الكل كمقروء" marks every notification read', (
    tester,
  ) async {
    await setPhoneViewport(tester);

    await tester.pumpWidget(buildTestableScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.text('تحديد الكل كمقروء'));
    await tester.pumpAndSettle();

    expect(repository.markAllCallCount, 1);
    // The link disappears once nothing is unread anymore.
    expect(find.text('تحديد الكل كمقروء'), findsNothing);
  });

  testWidgets('tapping the "المخزون" filter chip narrows the list', (
    tester,
  ) async {
    await setPhoneViewport(tester);

    await tester.pumpWidget(buildTestableScreen());
    await tester.pumpAndSettle();

    // The tabs scroll sideways, so this one may start off screen.
    await tester.ensureVisible(find.text('المخزون (1)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('المخزون (1)'));
    await tester.pumpAndSettle();

    expect(find.text('تنبيه نقص مخزون دواء Panadol'), findsOneWidget);
    expect(find.text('أضاف مريض تقييمًا جديدًا لصيدلية الشفاء'), findsNothing);
  });

  testWidgets('tapping an unread notification card marks it as read', (
    tester,
  ) async {
    await setPhoneViewport(tester);

    await tester.pumpWidget(buildTestableScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.text('تنبيه نقص مخزون دواء Panadol'));
    await tester.pumpAndSettle();

    expect(repository.lastMarkedId, 1);
  });

  testWidgets(
    'shows a back button (not a drawer hamburger) when pushed on top of another screen',
    (tester) async {
      await setPhoneViewport(tester);
      repository = _FakeNotificationsRepository();
      final sessionRepository = InMemorySessionRepository.pharmacy();
      final cubit = NotificationsCubit(
        GetNotificationsUseCase(repository, sessionRepository),
        MarkAllNotificationsReadUseCase(repository, sessionRepository),
        MarkNotificationReadUseCase(repository, sessionRepository),
      );
      addTearDown(cubit.close);

      // Mirrors how the app actually reaches this screen: pushed via
      // Navigator.pushNamed from a bell icon inside the shell, not as the
      // app's root route.
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) => MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Previous screen')),
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: cubit,
                          child: const PharmacyNotificationsScreen(),
                        ),
                      ),
                    ),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byType(AppBackButton), findsOneWidget);
      expect(find.byIcon(Icons.menu), findsNothing);
    },
  );
}
