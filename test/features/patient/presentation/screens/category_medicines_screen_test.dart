import 'package:daway_app/core/di/dependency_injection.dart';
import 'package:daway_app/core/localization/translations.dart';
import 'package:daway_app/features/patient/domain/entities/category.dart';
import 'package:daway_app/features/patient/presentation/cubit/category_medicines_cubit.dart';
import 'package:daway_app/features/patient/presentation/cubit/category_medicines_state.dart';
import 'package:daway_app/features/patient/presentation/cubit/medicine_images_cubit.dart';
import 'package:daway_app/features/patient/presentation/screens/category_medicines_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/arabic_test_app.dart';

/// A cubit that stays on "loading": the screen's header, back button and
/// search field are what is under test, not the list.
class _LoadingCubit extends Cubit<CategoryMedicinesState> implements CategoryMedicinesCubit {
  _LoadingCubit() : super(const CategoryMedicinesLoading());

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _NoImagesCubit extends Cubit<Map<int, String?>> implements MedicineImagesCubit {
  _NoImagesCubit() : super(const {});

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

const _medicines = Category(
  id: 1,
  nameAr: 'أدوية',
  nameEn: 'Medicines',
  slug: 'medicines',
);

void main() {
  setUp(() {
    getIt
      ..registerFactoryParam<CategoryMedicinesCubit, Category, void>((_, _) => _LoadingCubit())
      ..registerFactory<MedicineImagesCubit>(_NoImagesCubit.new);
  });

  tearDown(() async {
    Translations.use('ar');
    await getIt.reset();
  });

  /// The screen opened over a home page, as the app does.
  Future<void> openScreen(WidgetTester tester, {Locale locale = const Locale('ar')}) async {
    await setDesignViewport(tester);
    await tester.pumpWidget(
      buildArabicTestApp(
        locale: locale,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const CategoryMedicinesScreen(category: _medicines),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    // Not pumpAndSettle: the loading state spins forever.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('has a back button that returns to the page before it', (tester) async {
    await openScreen(tester);

    expect(find.byKey(const ValueKey('authBackButton')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('authBackButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(CategoryMedicinesScreen), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('shows the Arabic name in Arabic', (tester) async {
    await openScreen(tester);

    expect(find.text('أدوية'), findsOneWidget);
    expect(find.text('Medicines'), findsNothing);
  });

  testWidgets('shows the backend\'s English name in English', (tester) async {
    Translations.use('en');
    await openScreen(tester, locale: const Locale('en'));

    expect(find.text('Medicines'), findsOneWidget);
    expect(find.text('أدوية'), findsNothing);
    expect(find.text('Browse all the Medicines options we have.'), findsOneWidget);
    expect(find.byKey(const ValueKey('authBackButton')), findsOneWidget);
  });
}
