import 'package:budget_tracker_mobile/shared/widgets/scaffold_with_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

GoRouter buildRouter() {
  return GoRouter(
    routes: <RouteBase>[
      ShellRoute(
        builder: (_, __, child) => ScaffoldWithNav(child: child),
        routes: <RouteBase>[
          GoRoute(path: '/', builder: (_, __) => const Text('Dashboard')),
          GoRoute(path: '/gam3as', builder: (_, __) => const Text('Gam3as')),
          GoRoute(
            path: '/scenario',
            builder: (_, __) => const Text('Scenario'),
          ),
        ],
      ),
    ],
  );
}

void main() {
  testWidgets('narrow screen shows NavigationBar and routes to gam3as', (
    WidgetTester tester,
  ) async {
    final GoRouter router = buildRouter();
    addTearDown(router.dispose);

    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);

    await tester.tap(find.text('Gam3as'));
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/gam3as');
    expect(find.text('Gam3as'), findsWidgets);
  });

  testWidgets('wide screen shows NavigationRail and routes to scenario', (
    WidgetTester tester,
  ) async {
    final GoRouter router = buildRouter();
    addTearDown(router.dispose);

    await tester.binding.setSurfaceSize(const Size(800, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.text('Scenario'));
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/scenario');
    expect(find.text('Scenario'), findsWidgets);
  });
}
