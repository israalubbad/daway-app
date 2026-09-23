import 'dart:io';

import 'package:daway_app/core/helpers/api_result.dart';
import 'package:daway_app/core/routing/routes.dart';
import 'package:daway_app/features/auth/domain/entities/account_type.dart';
import 'package:daway_app/features/auth/domain/entities/patient_auth_result.dart';
import 'package:daway_app/features/auth/domain/entities/pharmacy_auth_result.dart';
import 'package:daway_app/features/auth/domain/entities/user_session.dart';
import 'package:daway_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:daway_app/features/auth/domain/repositories/session_repository.dart';
import 'package:daway_app/features/auth/domain/usecases/logout_usecase.dart';
import 'package:daway_app/features/auth/presentation/cubit/logout_cubit.dart';
import 'package:daway_app/features/patient/domain/repositories/avatar_repository.dart';
import 'package:daway_app/features/patient/domain/usecases/upload_avatar_usecase.dart';
import 'package:daway_app/features/pharmacy/domain/entities/pharmacy_dashboard_stats.dart';
import 'package:daway_app/features/pharmacy/domain/entities/pharmacy_profile.dart';
import 'package:daway_app/features/pharmacy/domain/repositories/pharmacy_dashboard_repository.dart';
import 'package:daway_app/features/pharmacy/domain/repositories/pharmacy_profile_repository.dart';
import 'package:daway_app/features/pharmacy/domain/usecases/get_pharmacy_dashboard_stats_usecase.dart';
import 'package:daway_app/features/pharmacy/domain/usecases/get_pharmacy_profile_usecase.dart';
import 'package:daway_app/features/pharmacy/domain/usecases/update_pharmacy_profile_usecase.dart';
import 'package:daway_app/features/pharmacy/presentation/cubit/pharmacy_dashboard_cubit.dart';
import 'package:daway_app/features/pharmacy/presentation/cubit/pharmacy_profile_cubit.dart';
import 'package:daway_app/features/pharmacy/presentation/screens/pharmacy_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<ApiResult<String?>> sendOtp({required String phone}) async =>
      const Success(null);

  @override
  Future<ApiResult<PatientAuthResult>> verifyOtp({
    required String phone,
    required String otp,
    String? name,
    String? birthDate,
    double? latitude,
    double? longitude,
    bool? notificationsEnabled,
  }) async =>
      const Success(PatientAuthResult(token: 'tok', isNewAccount: false));

  @override
  Future<ApiResult<PharmacyAuthResult>> pharmacyLogin({
    required String pharmacyId,
    required String password,
  }) async => const Success(PharmacyAuthResult(token: 'tok'));

  @override
  Future<ApiResult<void>> registerPharmacy({
    required String pharmacyName,
    required String phone,
    required String region,
    required String password,
  }) async => const Success(null);

  @override
  Future<ApiResult<void>> logout({required String token}) async =>
      const Success(null);
}

class _FakeSessionRepository implements SessionRepository {
  UserSession? savedSession = const UserSession(
    accountType: AccountType.pharmacy,
    token: 'tok-1',
  );

  @override
  Future<void> saveSession(UserSession session) async {
    savedSession = session;
  }

  @override
  Future<UserSession?> getSession() async => savedSession;

  @override
  Future<void> clearSession() async {
    savedSession = null;
  }
}

class _FakePharmacyDashboardRepository implements PharmacyDashboardRepository {
  final PharmacyDashboardStats stats;

  const _FakePharmacyDashboardRepository(this.stats);

  @override
  Future<ApiResult<PharmacyDashboardStats>> getDashboardStats({
    required String token,
  }) async => Success(stats);
}

const _profile = PharmacyProfile(
  pharmacyId: 'PH-1234',
  name: 'صيدلية النور',
  phone: '+970591234567',
  address: 'غزة الرمال',
);

class _FakePharmacyProfileRepository implements PharmacyProfileRepository {
  @override
  Future<ApiResult<PharmacyProfile>> getProfile({required String token}) async =>
      const Success(_profile);

  @override
  Future<ApiResult<void>> updateProfile({
    required String token,
    required PharmacyProfile profile,
  }) async => const Success(null);
}

class _FakeAvatarRepository implements AvatarRepository {
  @override
  Future<ApiResult<String>> uploadAvatar(File imageFile) async =>
      const Success('https://example.com/logo.jpg');
}

const _emptyStats = PharmacyDashboardStats(
  totalMedicines: 0,
  availableCount: 0,
  lowStockCount: 0,
  outOfStockCount: 0,
  newInquiriesCount: 0,
  averageRating: null,
  ratingsCount: 0,
  lowStockItems: [],
  recentInquiries: [],
);

const _populatedStats = PharmacyDashboardStats(
  totalMedicines: 120,
  availableCount: 45,
  lowStockCount: 30,
  outOfStockCount: 75,
  newInquiriesCount: 3,
  averageRating: 4.5,
  ratingsCount: 6,
  lowStockItems: [],
  recentInquiries: [],
);

void main() {
  Future<void> setPhoneViewport(WidgetTester tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Widget buildTestableScreen(
    LogoutCubit logoutCubit,
    PharmacyDashboardStats stats, {
    List<String>? visitedRoutes,
  }) {
    final dashboardCubit = PharmacyDashboardCubit(
      GetPharmacyDashboardStatsUseCase(
        _FakePharmacyDashboardRepository(stats),
        _FakeSessionRepository(),
      ),
    );
    addTearDown(dashboardCubit.close);

    final profileCubit = PharmacyProfileCubit(
      GetPharmacyProfileUseCase(
        _FakePharmacyProfileRepository(),
        _FakeSessionRepository(),
      ),
      UpdatePharmacyProfileUseCase(
        _FakePharmacyProfileRepository(),
        _FakeSessionRepository(),
      ),
      UploadAvatarUseCase(_FakeAvatarRepository()),
    );
    addTearDown(profileCubit.close);

    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, child) => MaterialApp(
        onGenerateRoute: (settings) {
          visitedRoutes?.add(settings.name ?? '');
          return MaterialPageRoute(
            builder: (_) => const Scaffold(body: SizedBox.shrink()),
          );
        },
        home: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: logoutCubit),
            BlocProvider.value(value: dashboardCubit),
            BlocProvider.value(value: profileCubit),
          ],
          child: const PharmacyHomeScreen(),
        ),
      ),
    );
  }

  testWidgets('shows the pharmacy name and address from the profile', (
    tester,
  ) async {
    await setPhoneViewport(tester);
    final cubit = LogoutCubit(
      LogoutUseCase(_FakeAuthRepository(), _FakeSessionRepository()),
    );
    addTearDown(cubit.close);

    await tester.pumpWidget(buildTestableScreen(cubit, _populatedStats));
    await tester.pumpAndSettle();

    expect(find.textContaining('صيدلية النور'), findsOneWidget);
    expect(find.text('غزة الرمال'), findsOneWidget);
  });

  group('empty state (no medicines yet)', () {
    testWidgets('shows the dashed add-medicine-file card', (tester) async {
      await setPhoneViewport(tester);
      final cubit = LogoutCubit(
        LogoutUseCase(_FakeAuthRepository(), _FakeSessionRepository()),
      );
      addTearDown(cubit.close);

      await tester.pumpWidget(buildTestableScreen(cubit, _emptyStats));
      await tester.pumpAndSettle();

      expect(find.text('أضف ملف الأدوية'), findsOneWidget);
    });

    testWidgets('shows zeroed-out stats and no orders section', (
      tester,
    ) async {
      await setPhoneViewport(tester);
      final cubit = LogoutCubit(
        LogoutUseCase(_FakeAuthRepository(), _FakeSessionRepository()),
      );
      addTearDown(cubit.close);

      await tester.pumpWidget(buildTestableScreen(cubit, _emptyStats));
      await tester.pumpAndSettle();

      expect(find.text('0'), findsNWidgets(4)); // products, out, low, available
      expect(find.text('—'), findsNWidgets(2)); // sales placeholder + no rating
      expect(find.text('الطلبات'), findsNothing);
    });

    testWidgets('tapping the add-medicine card navigates to the add screen', (
      tester,
    ) async {
      await setPhoneViewport(tester);
      final cubit = LogoutCubit(
        LogoutUseCase(_FakeAuthRepository(), _FakeSessionRepository()),
      );
      addTearDown(cubit.close);

      final visitedRoutes = <String>[];
      await tester.pumpWidget(
        buildTestableScreen(cubit, _emptyStats, visitedRoutes: visitedRoutes),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('أضف ملف الأدوية'));
      await tester.pumpAndSettle();

      expect(visitedRoutes, contains(Routes.addPharmacyMedicineScreen));
    });
  });

  group('populated state (has medicines)', () {
    testWidgets('hides the dashed add-medicine-file card', (tester) async {
      await setPhoneViewport(tester);
      final cubit = LogoutCubit(
        LogoutUseCase(_FakeAuthRepository(), _FakeSessionRepository()),
      );
      addTearDown(cubit.close);

      await tester.pumpWidget(buildTestableScreen(cubit, _populatedStats));
      await tester.pumpAndSettle();

      expect(find.text('أضف ملف الأدوية'), findsNothing);
    });

    testWidgets('shows the real stats and the pending orders section', (
      tester,
    ) async {
      await setPhoneViewport(tester);
      final cubit = LogoutCubit(
        LogoutUseCase(_FakeAuthRepository(), _FakeSessionRepository()),
      );
      addTearDown(cubit.close);

      await tester.pumpWidget(buildTestableScreen(cubit, _populatedStats));
      await tester.pumpAndSettle();

      expect(find.text('120'), findsOneWidget); // totalMedicines
      expect(find.text('75'), findsOneWidget); // outOfStockCount
      expect(find.text('30'), findsOneWidget); // lowStockCount
      expect(find.text('45'), findsOneWidget); // availableCount
      expect(find.text('4.5'), findsOneWidget); // averageRating
      expect(find.text('الطلبات'), findsOneWidget);
      expect(find.text('ميزة الطلبات قريباً'), findsOneWidget);
    });
  });

  testWidgets('navigates to account-type screen once logged out', (
    tester,
  ) async {
    await setPhoneViewport(tester);
    final cubit = LogoutCubit(
      LogoutUseCase(_FakeAuthRepository(), _FakeSessionRepository()),
    );
    addTearDown(cubit.close);

    final visitedRoutes = <String>[];
    await tester.pumpWidget(
      buildTestableScreen(cubit, _populatedStats, visitedRoutes: visitedRoutes),
    );
    await tester.pumpAndSettle();

    await cubit.logout();
    await tester.pumpAndSettle();

    expect(cubit.state.isLoggedOut, isTrue);
    expect(visitedRoutes, contains(Routes.accountTypeScreen));
  });
}
