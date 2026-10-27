import 'package:daway_app/core/routing/routes.dart';
import 'package:daway_app/features/chat/domain/entities/chatbot_reply.dart';
import 'package:daway_app/features/chat/presentation/widgets/chatbot_result_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

const _reply = ChatbotReply(
  medicine: ChatbotMedicine(
    id: 8,
    name: 'Brufen',
    nameAr: 'بروفين',
    activeIngredient: 'Paracetamol 500 mg',
  ),
  pharmacies: [
    ChatbotPharmacy(
      pharmacyId: 1,
      name: 'صيدلية الأمل',
      price: 10,
      availability: 'available',
      isOpenNow: true,
      address: 'غزة، شارع الوحدة',
    ),
    ChatbotPharmacy(
      pharmacyId: 2,
      name: 'صيدلية الشفاء',
      price: 12.5,
      availability: 'available',
      distanceKm: 3.25,
      isOpenNow: false,
      address: 'نابلس',
    ),
  ],
  alternatives: [ChatbotMedicine(id: 9, name: 'Advil', nameAr: 'ادفيل')],
  totalFound: 2,
);

void main() {
  Future<List<Object?>> open(WidgetTester tester, ChatbotReply reply) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final opened = <Object?>[];
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(440, 956),
        builder: (context, child) => MaterialApp(
          onGenerateRoute: (settings) {
            if (settings.name == Routes.medicineDetailScreen) opened.add(settings.arguments);
            return MaterialPageRoute(builder: (_) => const Scaffold(body: SizedBox.shrink()));
          },
          home: Scaffold(body: SingleChildScrollView(child: ChatbotResults(reply: reply))),
        ),
      ),
    );
    return opened;
  }

  testWidgets('shows the medicine and each pharmacy with its price and status', (tester) async {
    await open(tester, _reply);

    expect(find.text('بروفين'), findsOneWidget);
    expect(find.text('Brufen'), findsOneWidget);
    expect(find.text('Paracetamol 500 mg'), findsOneWidget);
    expect(find.text('صيدلية الأمل'), findsOneWidget);
    expect(find.text('صيدلية الشفاء'), findsOneWidget);
    expect(find.text('10 \$'), findsOneWidget);
    expect(find.text('12.50 \$'), findsOneWidget);
    expect(find.text('غزة، شارع الوحدة'), findsOneWidget);
    expect(find.text('نابلس · 3.3 كم'), findsOneWidget);
    expect(find.text('متوفر'), findsNWidgets(2));
    expect(find.text('مفتوحة الآن'), findsOneWidget);
    expect(find.text('مغلقة الآن'), findsOneWidget);
  });

  testWidgets('shows the alternatives under their own title', (tester) async {
    await open(tester, _reply);

    expect(find.text('البدائل'), findsOneWidget);
    expect(find.text('ادفيل'), findsOneWidget);
  });

  testWidgets('has no alternatives title when there are none', (tester) async {
    await open(
      tester,
      const ChatbotReply(medicine: ChatbotMedicine(id: 8, name: 'Brufen', nameAr: 'بروفين')),
    );

    expect(find.text('البدائل'), findsNothing);
  });

  testWidgets('tapping the medicine or a pharmacy opens that medicine', (tester) async {
    final opened = await open(tester, _reply);

    await tester.tap(find.text('بروفين'));
    await tester.pumpAndSettle();
    expect(opened, [8]);

    Navigator.of(tester.element(find.byType(Scaffold).first)).maybePop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('صيدلية الأمل'));
    await tester.pumpAndSettle();
    expect(opened, [8, 8]);
  });

  testWidgets('tapping an alternative opens the alternative', (tester) async {
    final opened = await open(tester, _reply);

    await tester.tap(find.text('ادفيل'));
    await tester.pumpAndSettle();

    expect(opened, [9]);
  });
}
