import 'package:daway_app/app.dart';
import 'package:daway_app/core/di/dependency_injection.dart';
import 'package:daway_app/core/routing/app_router.dart';
import 'package:daway_app/core/routing/routes.dart';
import 'package:daway_app/features/auth/domain/entities/account_type.dart';
import 'package:daway_app/features/auth/presentation/cubit/account_type_cubit.dart';
import 'package:daway_app/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:daway_app/features/onboarding/domain/usecases/get_onboarding_seen_usecase.dart';
import 'package:daway_app/features/onboarding/domain/usecases/set_onboarding_seen_usecase.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'features/localization/language_test_fakes.dart';
import 'helpers/arabic_test_app.dart';

class _Onboarding implements OnboardingRepository {
  @override
  Future<bool> isOnboardingSeen(AccountType accountType) async => false;

  @override
  Future<void> setOnboardingSeen(AccountType accountType) async {}
}

void main() {
  setUp(() {
    registerLanguageCubit(getIt);
    getIt.registerFactory(
      () => AccountTypeCubit(
        GetOnboardingSeenUseCase(_Onboarding()),
        SetOnboardingSeenUseCase(_Onboarding()),
      ),
    );
  });

  tearDown(() => getIt.reset());

  testWidgets('the initial route is the only route: nothing sits under it to go back to', (
    tester,
  ) async {
    await setDesignViewport(tester);
    await tester.pumpWidget(
      DawayApp(appRouter: AppRouter(), initialRoute: Routes.accountTypeScreen),
    );
    await tester.pumpAndSettle();

    expect(find.text('صيدلي'), findsOneWidget);
    expect(find.textContaining('No route defined'), findsNothing);
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    expect(navigator.canPop(), isFalse);
  });
}
