import 'package:daway_app/core/di/dependency_injection.dart';
import 'package:daway_app/core/erroring/failure.dart';
import 'package:daway_app/core/helpers/api_result.dart';
import 'package:daway_app/core/models/picked_location.dart';
import 'package:daway_app/core/routing/routes.dart';
import 'package:daway_app/core/widgets/incomplete_profile_banner.dart';
import 'package:daway_app/core/widgets/app_toggle_switch.dart';
import 'package:daway_app/features/auth/domain/entities/closure_request.dart';
import 'package:daway_app/features/auth/domain/usecases/get_pharmacy_closure_request_usecase.dart';
import 'package:daway_app/features/auth/domain/usecases/request_pharmacy_closure_usecase.dart';
import 'package:daway_app/features/auth/presentation/cubit/pharmacy_closure_cubit.dart';
import 'package:daway_app/features/auth/presentation/cubit/logout_cubit.dart';
import 'package:daway_app/features/auth/presentation/cubit/logout_state.dart';
import 'package:daway_app/features/patient/domain/entities/account_settings.dart';
import 'package:daway_app/features/patient/presentation/cubit/account_settings_cubit.dart';
import 'package:daway_app/features/patient/presentation/cubit/account_settings_state.dart';
import 'package:daway_app/features/pharmacy/domain/entities/pharmacy_profile.dart';
import 'package:daway_app/features/pharmacy/presentation/cubit/pharmacy_profile_cubit.dart';
import 'package:daway_app/features/pharmacy/presentation/cubit/pharmacy_profile_state.dart';
import 'package:daway_app/features/pharmacy/presentation/screens/pharmacy_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/arabic_test_app.dart';
import '../../../auth/account_closure_test_fakes.dart';
import '../../../localization/language_test_fakes.dart';

const _located = PharmacyProfile(
  pharmacyId: 'PH-1234',
  name: 'صيدلية النور',
  phone: '+970595554729',
  latitude: 31.5,
  longitude: 34.47,
  address: 'غزة-السرايا',
);

const _unlocated = PharmacyProfile(
  pharmacyId: 'PH-1234',
  name: 'صيدلية النور',
  phone: '+970595554729',
);

class _FakeProfileCubit extends Cubit<PharmacyProfileState>
    implements PharmacyProfileCubit {
  _FakeProfileCubit(super.initial);

  int saves = 0;
  int discards = 0;
  String? saveError;

  PharmacyProfileLoaded get loaded => state as PharmacyProfileLoaded;

  @override
  void locationSelected(PickedLocation location) => emit(
    loaded.copyWith(
      latitude: location.latitude,
      longitude: location.longitude,
      address: location.address,
    ),
  );

  @override
  Future<void> save() async {
    saves++;
    final error = saveError;
    emit(
      error == null
          ? PharmacyProfileLoaded.fromProfile(
              PharmacyProfile(
                pharmacyId: loaded.profile.pharmacyId,
                name: loaded.name,
                phone: loaded.profile.phone,
                latitude: loaded.latitude,
                longitude: loaded.longitude,
                address: loaded.address,
              ),
            )
          : loaded.copyWith(saveError: error),
    );
  }

  @override
  void discardEdits() {
    discards++;
    emit(PharmacyProfileLoaded.fromProfile(loaded.profile));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAccountSettingsCubit extends Cubit<AccountSettingsState>
    implements AccountSettingsCubit {
  _FakeAccountSettingsCubit(super.initial);

  @override
  Future<void> refresh() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeLogoutCubit extends Cubit<LogoutState> implements LogoutCubit {
  _FakeLogoutCubit() : super(const LogoutState());

  int logouts = 0;

  @override
  Future<void> logout() async => logouts++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeProfileCubit profileCubit;
  late _FakeLogoutCubit logoutCubit;
  late FakeAccountClosureRepository closureRepository;
  late FakeClosureSessionRepository closureSession;

  AccountSettingsState notificationsOn() => const AccountSettingsLoaded(
    AccountSettings(
      notificationsEnabled: true,
      locationEnabled: true,
      appVersion: '1.0.0',
    ),
  );

  setUp(() {
    registerLanguageCubit(getIt);
    logoutCubit = _FakeLogoutCubit();
    closureRepository = FakeAccountClosureRepository();
    closureSession = FakeClosureSessionRepository();
  });

  tearDown(() async {
    await profileCubit.close();
    await logoutCubit.close();
    await getIt.reset();
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    PharmacyProfile profile = _located,
    AccountSettingsState? settings,
  }) async {
    profileCubit = _FakeProfileCubit(
      PharmacyProfileLoaded.fromProfile(profile),
    );
    getIt.registerFactory<AccountSettingsCubit>(
      () => _FakeAccountSettingsCubit(settings ?? notificationsOn()),
    );
    getIt.registerFactory<PharmacyClosureCubit>(
      () => PharmacyClosureCubit(
        GetPharmacyClosureRequestUseCase(closureRepository, closureSession),
        RequestPharmacyClosureUseCase(closureRepository, closureSession),
      ),
    );
    await setDesignViewport(tester);
    await tester.pumpWidget(
      buildArabicTestApp(
        onGenerateRoute: (route) {
          if (route.name != Routes.locationPickerScreen) return null;
          return MaterialPageRoute<PickedLocation>(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).pop(
                  const PickedLocation(
                    latitude: 31.4,
                    longitude: 34.3,
                    address: 'خان يونس',
                  ),
                ),
                child: const Text('confirm location'),
              ),
            ),
          );
        },
        home: MultiBlocProvider(
          providers: [
            BlocProvider<PharmacyProfileCubit>.value(value: profileCubit),
            BlocProvider<LogoutCubit>.value(value: logoutCubit),
          ],
          child: const PharmacySettingsScreen(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows the design\'s rows and sections', (tester) async {
    await pumpScreen(tester);

    expect(find.text('الإعدادات'), findsOneWidget);
    for (final text in [
      'التفضيلات',
      'معلومات الحساب',
      'اللغة',
      'العربية',
      'الإشعارات',
      'تحديث الموقع',
      'الخصوصية والأمان',
      'سياسة الخصوصية',
      'الشروط والأحكام',
      'الحساب',
      'تسجيل الخروج',
      'طلب إغلاق الحساب',
      'دواك',
      'الإصدار 1.0.0',
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
  });

  testWidgets('has no back chip: it is a tab\'s root screen', (tester) async {
    await pumpScreen(tester);

    expect(find.byKey(const ValueKey('authBackButton')), findsNothing);
  });

  testWidgets(
    'the notifications switch is on when the device allows notifications',
    (tester) async {
      await pumpScreen(tester);

      expect(
        tester.widget<AppToggleSwitch>(find.byType(AppToggleSwitch)).value,
        isTrue,
      );
    },
  );

  testWidgets(
    'the notifications switch is off when the device blocks notifications',
    (tester) async {
      await pumpScreen(
        tester,
        settings: const AccountSettingsLoaded(
          AccountSettings(notificationsEnabled: false, locationEnabled: false),
        ),
      );

      expect(
        tester.widget<AppToggleSwitch>(find.byType(AppToggleSwitch)).value,
        isFalse,
      );
    },
  );

  testWidgets('a pharmacy with no location is asked to set one', (
    tester,
  ) async {
    await pumpScreen(tester, profile: _unlocated);

    expect(find.byType(IncompleteProfileBanner), findsOneWidget);
  });

  testWidgets('a pharmacy with a location is not', (tester) async {
    await pumpScreen(tester);

    expect(find.byType(IncompleteProfileBanner), findsNothing);
  });

  testWidgets('تحديث الموقع opens the map and saves what it confirms', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.text('تحديث الموقع'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('confirm location'));
    await tester.pumpAndSettle();

    expect(profileCubit.saves, 1);
    expect(profileCubit.loaded.address, 'خان يونس');
    expect(find.text('تم تحديث الموقع'), findsOneWidget);
  });

  testWidgets('backing out of the map saves nothing', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('تحديث الموقع'));
    await tester.pumpAndSettle();
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();

    expect(profileCubit.saves, 0);
  });

  testWidgets(
    'a failed location save shows the error and drops the unsaved location',
    (tester) async {
      await pumpScreen(tester);
      profileCubit.saveError = 'فشل الحفظ';

      await tester.tap(find.text('تحديث الموقع'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('confirm location'));
      await tester.pumpAndSettle();

      expect(find.text('فشل الحفظ'), findsOneWidget);
      expect(profileCubit.discards, 1);
      expect(profileCubit.loaded.address, 'غزة-السرايا');
    },
  );

  testWidgets('معلومات الحساب opens the account-info screen', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('معلومات الحساب'));
    await tester.pumpAndSettle();

    expect(find.text('إدارة معلومات صيدليتك وتفاصيلها'), findsOneWidget);
    expect(find.text('حفظ التعديلات'), findsOneWidget);
  });

  testWidgets('تسجيل الخروج asks first, then logs out', (tester) async {
    await pumpScreen(tester);

    await tester.ensureVisible(find.text('تسجيل الخروج'));
    await tester.tap(find.text('تسجيل الخروج'));
    await tester.pumpAndSettle();
    expect(find.text('تسجيل الخروج؟'), findsOneWidget);
    expect(logoutCubit.logouts, 0);

    await tester.tap(find.text('تسجيل الخروج').last);
    await tester.pumpAndSettle();

    expect(logoutCubit.logouts, 1);
  });

  group('asking to close the account', () {
    Future<void> openClosureSheet(WidgetTester tester) async {
      await tester.ensureVisible(find.text('طلب إغلاق الحساب'));
      await tester.tap(find.text('طلب إغلاق الحساب'));
      await tester.pumpAndSettle();
    }

    testWidgets('asks first, and nothing is sent until it is confirmed', (tester) async {
      await pumpScreen(tester);

      await openClosureSheet(tester);

      expect(find.text('طلب إغلاق الحساب؟'), findsOneWidget);
      expect(find.text('السبب (اختياري)'), findsOneWidget);
      expect(closureRepository.requestCount, 0);
    });

    testWidgets('confirming sends the reason, closes the sheet and says it was sent',
        (tester) async {
      await pumpScreen(tester);
      await openClosureSheet(tester);
      await tester.enterText(find.byType(TextField), 'إغلاق نهائي');

      await tester.tap(find.widgetWithText(ElevatedButton, 'إرسال الطلب'));
      await tester.pumpAndSettle();

      expect(closureRepository.requestCount, 1);
      expect(closureRepository.lastReason, 'إغلاق نهائي');
      expect(find.text('طلب إغلاق الحساب؟'), findsNothing);
      expect(find.text('تم إرسال طلب إغلاق الحساب، سيتم مراجعته من الإدارة'), findsOneWidget);
      // The row now shows where the request stands, and the pharmacy stays signed in.
      expect(find.text('قيد المراجعة'), findsOneWidget);
      expect(closureSession.savedSession, isNotNull);
    });

    testWidgets('a refusal is shown in the sheet', (tester) async {
      closureRepository.requestResult = const ApiError(ApiFailure(message: 'يوجد طلب مفتوح'));
      await pumpScreen(tester);
      await openClosureSheet(tester);

      await tester.tap(find.widgetWithText(ElevatedButton, 'إرسال الطلب'));
      await tester.pumpAndSettle();

      expect(find.text('يوجد طلب مفتوح'), findsOneWidget);
      expect(find.text('طلب إغلاق الحساب؟'), findsOneWidget);
    });

    testWidgets('cancelling sends nothing', (tester) async {
      await pumpScreen(tester);
      await openClosureSheet(tester);

      await tester.tap(find.text('إلغاء'));
      await tester.pumpAndSettle();

      expect(find.text('طلب إغلاق الحساب؟'), findsNothing);
      expect(closureRepository.requestCount, 0);
    });

    testWidgets('a request already waiting shows its status and is not asked for again',
        (tester) async {
      closureRepository.getRequestResult = const Success(pendingRequest);
      await pumpScreen(tester);
      await tester.pumpAndSettle();

      expect(find.text('قيد المراجعة'), findsOneWidget);
      await tester.ensureVisible(find.text('طلب إغلاق الحساب'));
      await tester.tap(find.text('طلب إغلاق الحساب'));
      await tester.pumpAndSettle();

      expect(find.text('طلب إغلاق الحساب؟'), findsNothing);
      expect(find.text('طلب إغلاق حسابك قيد المراجعة من الإدارة'), findsOneWidget);
      expect(closureRepository.requestCount, 0);
    });

    testWidgets('a rejected request may be asked again', (tester) async {
      closureRepository.getRequestResult = const Success(
        ClosureRequest(status: ClosureRequestStatus.rejected),
      );
      await pumpScreen(tester);
      await tester.pumpAndSettle();

      expect(find.text('تم الرفض'), findsOneWidget);
      await openClosureSheet(tester);

      expect(find.text('طلب إغلاق الحساب؟'), findsOneWidget);
    });

    testWidgets('the row still works when the request could not be read', (tester) async {
      closureRepository.getRequestResult = const ApiError(ApiFailure(message: 'تعذر الاتصال'));
      await pumpScreen(tester);
      await tester.pumpAndSettle();

      await openClosureSheet(tester);

      expect(find.text('طلب إغلاق الحساب؟'), findsOneWidget);
    });
  });
}
