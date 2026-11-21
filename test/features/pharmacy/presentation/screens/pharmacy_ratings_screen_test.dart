import 'package:daway_app/core/helpers/api_result.dart';
import 'package:daway_app/features/pharmacy/domain/entities/rating.dart';
import 'package:daway_app/features/pharmacy/domain/repositories/pharmacy_ratings_repository.dart';
import 'package:daway_app/features/pharmacy/domain/usecases/get_pharmacy_ratings_usecase.dart';
import 'package:daway_app/features/pharmacy/presentation/cubit/pharmacy_ratings_cubit.dart';
import 'package:daway_app/features/pharmacy/presentation/screens/pharmacy_ratings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../helpers/in_memory_session_repository.dart';

final _rating = Rating(
  id: 1,
  stars: 5,
  comment: 'خدمة ممتازة وسريعة جدًا',
  createdAt: DateTime.now().subtract(const Duration(hours: 1)),
  patientName: 'أحمد العتيبي',
);

class _FakePharmacyRatingsRepository implements PharmacyRatingsRepository {
  double averageRating = 4.7;

  @override
  Future<ApiResult<RatingsOverview>> getRatings({required String token}) async {
    return Success(
      RatingsOverview(
        ratings: [_rating],
        totalCount: 128,
        averageRating: averageRating,
        starCounts: const {5: 96, 4: 21, 3: 7, 2: 3, 1: 1},
      ),
    );
  }
}

void main() {
  Future<void> setPhoneViewport(WidgetTester tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Widget buildTestableScreen({_FakePharmacyRatingsRepository? repositoryOverride}) {
    final repository = repositoryOverride ?? _FakePharmacyRatingsRepository();
    final sessionRepository = InMemorySessionRepository.pharmacy();
    final cubit = PharmacyRatingsCubit(
      GetPharmacyRatingsUseCase(repository, sessionRepository),
    );
    addTearDown(cubit.close);

    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, child) => MaterialApp(
        home: BlocProvider.value(value: cubit, child: const PharmacyRatingsScreen()),
      ),
    );
  }

  testWidgets('puts the reviews right under the title', (tester) async {
    await setPhoneViewport(tester);

    await tester.pumpWidget(buildTestableScreen());
    await tester.pumpAndSettle();

    expect(find.text('التقييمات'), findsOneWidget);
    expect(find.text('أحمد العتيبي'), findsOneWidget);
    expect(find.text('5.0'), findsOneWidget);
    expect(find.text('خدمة ممتازة وسريعة جدًا'), findsOneWidget);
  });
}
