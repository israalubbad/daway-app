import 'package:daway_app/features/pharmacy/presentation/widgets/accounting_entry_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/arabic_test_app.dart';

void main() {
  testWidgets('the arrow at the end of the card points left in Arabic, the way forward', (
    tester,
  ) async {
    await setDesignViewport(tester);
    await tester.pumpWidget(
      buildArabicTestApp(home: Scaffold(body: AccountingEntryCard(onTap: () {}))),
    );

    // chevron_right mirrors under right-to-left text: it is drawn pointing left
    // there, and pointing right in English (chevron_left was the other way round).
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    expect(find.byIcon(Icons.chevron_left_rounded), findsNothing);
    expect(Icons.chevron_right_rounded.matchTextDirection, isTrue);
  });

  testWidgets('tapping the card calls back', (tester) async {
    await setDesignViewport(tester);
    var taps = 0;
    await tester.pumpWidget(
      buildArabicTestApp(home: Scaffold(body: AccountingEntryCard(onTap: () => taps++))),
    );

    await tester.tap(find.text('المحاسبة'));

    expect(taps, 1);
  });
}
