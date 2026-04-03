import 'package:go_router/go_router.dart';

import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/gam3as/presentation/gam3as_screen.dart';
import '../../features/scenario/presentation/scenario_screen.dart';
import '../../shared/widgets/scaffold_with_nav.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    ShellRoute(
      builder: (context, state, child) => ScaffoldWithNav(child: child),
      routes: <RouteBase>[
        GoRoute(path: '/', builder: (_, __) => const DashboardScreen()),
        GoRoute(path: '/gam3as', builder: (_, __) => const Gam3asScreen()),
        GoRoute(path: '/scenario', builder: (_, __) => const ScenarioScreen()),
      ],
    ),
  ],
);
