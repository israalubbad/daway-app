import 'package:daway_app/app.dart';
import 'package:daway_app/core/di/dependency_injection.dart';
import 'package:daway_app/core/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../features/localization/language_test_fakes.dart';

class _StubRouter extends AppRouter {
  @override
  Route<dynamic> generateRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(body: Center(child: Text('page ${settings.name}'))),
    );
  }
}

void main() {
  setUp(() => registerLanguageCubit(getIt));
  tearDown(() => getIt.reset());

  testWidgets('the initial route is the only page: back from it has nothing under it',
      (tester) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(DawayApp(appRouter: _StubRouter(), initialRoute: '/home'));
    await tester.pumpAndSettle();

    expect(find.text('page /home'), findsOneWidget);
    expect(find.textContaining('page /'), findsOneWidget);
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    expect(navigator.canPop(), isFalse);
  });

  testWidgets('a page pushed on top pops back to the initial route', (tester) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(DawayApp(appRouter: _StubRouter(), initialRoute: '/home'));
    await tester.pumpAndSettle();
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));

    navigator.pushNamed('/chat');
    await tester.pumpAndSettle();
    expect(find.text('page /chat'), findsOneWidget);

    navigator.pop();
    await tester.pumpAndSettle();
    expect(find.text('page /home'), findsOneWidget);
    expect(navigator.canPop(), isFalse);
  });
}
