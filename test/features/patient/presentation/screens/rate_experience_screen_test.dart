import 'package:daway_app/core/helpers/api_result.dart';
import 'package:daway_app/core/widgets/star_rating.dart';
import 'package:daway_app/features/patient/domain/repositories/patient_ratings_repository.dart';
import 'package:daway_app/features/patient/domain/usecases/submit_pharmacy_rating_usecase.dart';
import 'package:daway_app/features/patient/presentation/cubit/rate_experience_cubit.dart';
import 'package:daway_app/features/patient/presentation/screens/rate_experience_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import '../../../../helpers/in_memory_session_repository.dart';

class _FakePatientRatingsRepository implements PatientRatingsRepository {
  ApiResult<void> result = const Success(null);
  int? lastStars;

  @override
  Future<ApiResult<void>> submitPharmacyRating({
    required String token,
    required int pharmacyId,
    required int stars,
    String? comment,
  }) async {
    lastStars = stars;
    return result;
  }
}

void main() {
  Future<void> setPhoneViewport(WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  // Registered directly via getIt (bypassing dependency_injection.dart's
  // wiring) the same way medicine_detail_screen_test.dart does.
  final getIt = GetIt.instance;
  late _FakePatientRatingsRepository repository;

  setUp(() {
    repository = _FakePatientRatingsRepository();
    final sessionRepository = InMemorySessionRepository.patient();
    getIt.registerFactoryParam<RateExperienceCubit, int, void>(
      (pharmacyId, _) => RateExperienceCubit(
        pharmacyId,
        SubmitPharmacyRatingUseCase(repository, sessionRepository),
      ),
    );
  });

  tearDown(() => getIt.reset());

  Widget buildTestableScreen() {
    return ScreenUtilInit(
      designSize: const Size(440, 956),
      builder: (context, child) => MaterialApp(
        home: RateExperienceScreen(pharmacyId: 11, pharmacyName: 'صيدلية النور'),
      ),
    );
  }

  testWidgets('shows the header with the pharmacy name and only the pharmacy card', (tester) async {
    await setPhoneViewport(tester);

    await tester.pumpWidget(buildTestableScreen());
    await tester.pumpAndSettle();

    expect(find.text('قيم تجربتك معنا'), findsOneWidget);
    expect(find.textContaining('صيدلية النور'), findsOneWidget);
    expect(find.text('تقييم التطبيق'), findsNothing);
    expect(find.text('تقييم الصيدلية'), findsOneWidget);
    expect(find.text('اضغط على نجمة لتقييم'), findsOneWidget);
  });

  testWidgets('tapping the 1st star shows the "سيء" label', (tester) async {
    await setPhoneViewport(tester);

    await tester.pumpWidget(buildTestableScreen());
    await tester.pumpAndSettle();
    // The header's own back button has a GestureDetector too, so look inside
    // the StarRating rather than over the whole tree.
    await tester.tap(
      find
          .descendant(of: find.byType(StarRating).first, matching: find.byType(GestureDetector))
          .first,
    );
    await tester.pumpAndSettle();

    expect(find.text('سيء'), findsOneWidget);
  });

  testWidgets('submitting with nothing rated shows a validation message', (tester) async {
    await setPhoneViewport(tester);

    await tester.pumpWidget(buildTestableScreen());
    await tester.pumpAndSettle();
    await tester.tap(find.text('إرسال التقييم'));
    await tester.pumpAndSettle();

    expect(find.text('يرجى اختيار تقييم للصيدلية'), findsOneWidget);
  });
}
