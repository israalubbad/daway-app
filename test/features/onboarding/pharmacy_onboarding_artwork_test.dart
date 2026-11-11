import 'package:daway_app/core/localization/translations.dart';
import 'package:daway_app/features/onboarding/domain/entities/onboarding_page.dart';
import 'package:daway_app/features/onboarding/presentation/onboarding_content.dart';
import 'package:daway_app/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/arabic_test_app.dart';

void main() {
  tearDown(() => Translations.use('ar'));

  Future<void> pumpOnboarding(WidgetTester tester, {Locale locale = const Locale('ar')}) async {
    await setDesignViewport(tester);
    await tester.pumpWidget(
      buildArabicTestApp(
        locale: locale,
        home: OnboardingScreen(pages: pharmacyOnboardingPages, onFinished: () {}),
      ),
    );
    await tester.pump();
  }

  /// Taps "التالي" and lets the next page start.
  Future<void> goToNextPage(WidgetTester tester) async {
    await tester.tap(find.text('التالي'));
    // The swipe's first frame moves nothing; the next one builds the page, and
    // the page's animation takes that frame as its start.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  /// The opacity the nearest [Opacity] above [finder] draws it with.
  double opacityOf(WidgetTester tester, Finder finder) =>
      tester.widget<Opacity>(find.ancestor(of: finder, matching: find.byType(Opacity)).first).opacity;

  /// The scale the products card is drawn at (1 when nothing scales it).
  double productsCardScale(WidgetTester tester) {
    final scaled = find.ancestor(
      of: find.text('إجمالي\nالمنتجات'),
      matching: find.byType(Transform),
    );
    return tester.widget<Transform>(scaled.first).transform.getMaxScaleOnAxis();
  }

  test('the three pharmacy pages each name a live picture', () {
    expect(
      [for (final page in pharmacyOnboardingPages) page.artwork],
      [
        OnboardingArtwork.pharmacyProducts,
        OnboardingArtwork.pharmacyOrders,
        OnboardingArtwork.pharmacyChat,
      ],
    );
  });

  testWidgets('page 1 draws the pharmacy home with the app\'s own widgets', (tester) async {
    await pumpOnboarding(tester);

    expect(find.text('تحكم بمنتجات صيدليتك'), findsOneWidget);
    expect(find.text('إجمالي\nالمنتجات'), findsOneWidget);
    expect(find.text('120'), findsOneWidget);
    expect(find.text('متوفرة'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a finger comes, taps the products card (it grows, then settles) and goes', (
    tester,
  ) async {
    await pumpOnboarding(tester);
    await tester.pump(); // the animation counts from the frame after it starts
    expect(find.byIcon(Icons.touch_app_rounded), findsOneWidget);
    expect(productsCardScale(tester), closeTo(1.0, 0.001));

    // 36% of the first 3.4 s tap: the finger is down.
    await tester.pump(const Duration(milliseconds: 1224));
    expect(productsCardScale(tester), greaterThan(1.05));

    // 60%: the finger has lifted and the card is back to its size.
    await tester.pump(const Duration(milliseconds: 816));
    expect(productsCardScale(tester), closeTo(1.0, 0.001));
  });

  testWidgets('after its taps the picture rests: no finger, nothing animating', (tester) async {
    await pumpOnboarding(tester);

    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.byIcon(Icons.touch_app_rounded), findsNothing);
    expect(productsCardScale(tester), closeTo(1.0, 0.001));
  });

  testWidgets('page 2 shows the orders screen with its cards sliding in one by one', (tester) async {
    await pumpOnboarding(tester);
    await goToNextPage(tester);
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('استقبل طلباتك بسهولة'), findsOneWidget);
    final first = opacityOf(tester, find.text('#DW-1042'));
    final last = opacityOf(tester, find.text('#DW-1040'));
    expect(first, greaterThan(0));
    expect(last, 0.0, reason: 'the last card has not started yet');

    await tester.pumpAndSettle();
    expect(opacityOf(tester, find.text('#DW-1040')), 1.0);
  });

  testWidgets('page 3 plays the chat: each message, then its reply, in turn', (tester) async {
    await pumpOnboarding(tester);
    await goToNextPage(tester);
    await tester.pumpAndSettle();
    await goToNextPage(tester);
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('تواصل مباشرة مع عملائك'), findsOneWidget);
    final asks = [find.text('هل بانادول متوفر عندكم؟'), find.text('بكم الشريط؟')];
    final answers = [find.text('أهلاً فيك، أكيد متوفر'), find.text('الشريط بـ 12 شيكل')];
    for (final message in [...asks, ...answers]) {
      expect(message, findsOneWidget);
    }
    // 600 ms in: the question is nearly in, the last answer is not yet.
    expect(opacityOf(tester, asks.first), greaterThan(0.5));
    expect(opacityOf(tester, answers.last), 0.0);

    await tester.pump(const Duration(milliseconds: 1000));
    // The first answer has come in after the question, the second question not yet.
    expect(opacityOf(tester, answers.first), greaterThan(0.5));
    expect(opacityOf(tester, asks.last), lessThan(opacityOf(tester, answers.first)));

    await tester.pumpAndSettle();
    expect(opacityOf(tester, answers.last), 1.0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('English: the pictures read in English and mirror', (tester) async {
    Translations.use('en');
    await pumpOnboarding(tester, locale: const Locale('en'));

    expect(find.text('Control your pharmacy\'s products'), findsOneWidget);
    expect(find.text('Total\nproducts'), findsOneWidget);
    expect(find.textContaining('Al-Nour Pharmacy', findRichText: true), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
