import 'package:go_router/go_router.dart';

import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/gam3as/domain/gam3a.dart';
import '../../features/gam3as/presentation/gam3a_form_screen.dart';
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
    GoRoute(
      path: '/gam3as/new',
      builder: (context, state) => const Gam3aFormScreen(existing: null),
    ),
    GoRoute(
      path: '/gam3as/edit',
      builder: (context, state) =>
          Gam3aFormScreen(existing: state.extra as Gam3a?),
    ),
  ],
);
