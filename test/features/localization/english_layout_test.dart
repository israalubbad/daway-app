import 'package:daway_app/core/localization/translations.dart';
import 'package:daway_app/features/auth/domain/entities/account_type.dart';
import 'package:daway_app/features/auth/presentation/cubit/account_type_cubit.dart';
import 'package:daway_app/features/auth/presentation/screens/account_type_screen.dart';
import 'package:daway_app/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:daway_app/features/onboarding/domain/usecases/get_onboarding_seen_usecase.dart';
import 'package:daway_app/features/onboarding/domain/usecases/set_onboarding_seen_usecase.dart';
import 'package:daway_app/features/patient/presentation/widgets/language_bottom_sheet.dart';
import 'package:daway_app/features/pharmacy/presentation/widgets/pharmacy_bottom_nav_bar.dart';
import 'package:daway_app/features/pharmacy/presentation/widgets/pharmacy_dashboard_tab_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/arabic_test_app.dart';

class _Onboarding implements OnboardingRepository {
  @override
  Future<bool> isOnboardingSeen(AccountType accountType) async => false;

  @override
  Future<void> setOnboardingSeen(AccountType accountType) async {}
}

/// The app in English: texts translated, layout mirrored (left-to-right), and
/// nothing overflowing where English words are longer than the Arabic ones.
void main() {
  setUp(() => Translations.use('en'));
  tearDown(() => Translations.use('ar'));

  Widget english(Widget home) => buildArabicTestApp(home: home, locale: const Locale('en'));

  testWidgets('English is left-to-right', (tester) async {
    await setDesignViewport(tester);
    late TextDirection direction;
    await tester.pumpWidget(
      english(
        Builder(
          builder: (context) {
            direction = Directionality.of(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(direction, TextDirection.ltr);
  });

  testWidgets('the pharmacy bottom bar reads in English with home leftmost', (tester) async {
    await setDesignViewport(tester);

    await tester.pumpWidget(
      english(
        Scaffold(
          bottomNavigationBar: PharmacyBottomNavBar(
            selectedTab: PharmacyDashboardTab.home,
            onTabSelected: (_) {},
          ),
        ),
      ),
    );

    const labels = ['Home', 'Products', 'Orders', 'Messages', 'Settings'];
    for (final label in labels) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    final xs = [for (final label in labels) tester.getCenter(find.text(label)).dx];
    expect(xs, orderedEquals([...xs]..sort()), reason: 'each tab sits right of the one before');
    expect(tester.takeException(), isNull);
  });

  testWidgets('the account type screen fits in English', (tester) async {
    await setDesignViewport(tester);
    final repository = _Onboarding();
    final cubit = AccountTypeCubit(
      GetOnboardingSeenUseCase(repository),
      SetOnboardingSeenUseCase(repository),
    );
    addTearDown(cubit.close);

    await tester.pumpWidget(
      english(BlocProvider.value(value: cubit, child: const AccountTypeScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('How will you use Dawak?'), findsOneWidget);
    expect(find.text('User'), findsOneWidget);
    expect(find.text('Pharmacist'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the language sheet reads in English and lists both languages', (tester) async {
    await setDesignViewport(tester);

    await tester.pumpWidget(
      english(const Scaffold(body: LanguageBottomSheet(selected: AppLanguage.english))),
    );

    expect(find.text('Choose language'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('العربية'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
