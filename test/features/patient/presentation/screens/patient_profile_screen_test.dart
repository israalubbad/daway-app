import 'dart:io';

import 'package:daway_app/core/helpers/api_result.dart';
import 'package:daway_app/features/auth/domain/entities/account_type.dart';
import 'package:daway_app/features/auth/domain/entities/user_session.dart';
import 'package:daway_app/features/auth/domain/repositories/session_repository.dart';
import 'package:daway_app/features/patient/domain/entities/patient_profile.dart';
import 'package:daway_app/features/patient/domain/repositories/avatar_repository.dart';
import 'package:daway_app/features/patient/domain/repositories/patient_profile_repository.dart';
import 'package:daway_app/features/patient/domain/usecases/get_patient_profile_usecase.dart';
import 'package:daway_app/features/patient/domain/usecases/update_patient_profile_usecase.dart';
import 'package:daway_app/features/patient/domain/usecases/upload_avatar_usecase.dart';
import 'package:daway_app/features/patient/presentation/cubit/patient_profile_cubit.dart';
import 'package:daway_app/features/patient/presentation/screens/patient_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

const _profile = PatientProfile(
  name: 'إسراء',
  phone: '0599123456',
  birthDate: '2000-01-01',
  latitude: 31.5,
  longitude: 34.46,
  address: 'غزة',
);

class _FakeProfileRepository implements PatientProfileRepository {
  PatientProfile? lastSaved;

  @override
  Future<ApiResult<PatientProfile>> getProfile({required String token}) async =>
      const Success(_profile);

  @override
  Future<ApiResult<void>> updateProfile({
    required String token,
    required PatientProfile profile,
  }) async {
    lastSaved = profile;
    return const Success(null);
  }
}

class _FakeAvatarRepository implements AvatarRepository {
  @override
  Future<ApiResult<String>> uploadAvatar(File imageFile) async => const Success('');
}

class _FakeSession implements SessionRepository {
  @override
  Future<UserSession?> getSession() async =>
      const UserSession(accountType: AccountType.patient, token: 'tok');

  @override
  Future<void> saveSession(UserSession session) async {}

  @override
  Future<void> clearSession() async {}
}

void main() {
  late _FakeProfileRepository repository;

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cubit = PatientProfileCubit(
      GetPatientProfileUseCase(repository, _FakeSession()),
      UpdatePatientProfileUseCase(repository, _FakeSession()),
      UploadAvatarUseCase(_FakeAvatarRepository()),
    );
    addTearDown(cubit.close);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(440, 956),
        builder: (context, child) => MaterialApp(
          home: BlocProvider.value(value: cubit, child: const PatientProfileScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() => repository = _FakeProfileRepository());

  testWidgets('shows the saved name in a field that can be typed in straight away',
      (tester) async {
    await pumpScreen(tester);

    expect(
      find.byWidgetPredicate((w) => w is TextField && w.controller?.text == 'إسراء'),
      findsOneWidget,
    );
    expect(find.text('تعديل'), findsNothing); // no separate "edit" step
  });

  testWidgets('the save button does nothing until something has changed', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('حفظ التعديلات'));
    await tester.pumpAndSettle();

    expect(repository.lastSaved, isNull);
  });

  testWidgets('typing a new name and saving sends it', (tester) async {
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextField), 'إسراء لبد');
    await tester.pump();
    await tester.ensureVisible(find.text('حفظ التعديلات'));
    await tester.tap(find.text('حفظ التعديلات'));
    await tester.pumpAndSettle();

    expect(repository.lastSaved?.name, 'إسراء لبد');
  });

  testWidgets('changing the name back to the saved one leaves nothing to save', (tester) async {
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextField), 'غير');
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'إسراء');
    await tester.pump();
    await tester.ensureVisible(find.text('حفظ التعديلات'));
    await tester.tap(find.text('حفظ التعديلات'));
    await tester.pumpAndSettle();

    expect(repository.lastSaved, isNull);
  });

  testWidgets('the phone number is shown as read only', (tester) async {
    await pumpScreen(tester);

    expect(find.text('0599123456'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget); // only the name is typed into
  });

  testWidgets('an empty name is flagged', (tester) async {
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextField), '');
    await tester.pump();

    expect(find.text('الاسم مطلوب'), findsOneWidget);
  });
}
