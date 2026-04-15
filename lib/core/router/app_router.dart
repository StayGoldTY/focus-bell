import 'package:go_router/go_router.dart';
import '../../features/timer/pages/timer_page.dart';
import '../../features/settings/pages/settings_page.dart';
import '../../features/principles/pages/principles_page.dart';
import '../../features/statistics/pages/statistics_page.dart';
import '../../shared/widgets/main_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/timer',
  routes: [
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/timer',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: TimerPage()),
        ),
        GoRoute(
          path: '/statistics',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: StatisticsPage()),
        ),
        GoRoute(
          path: '/principles',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: PrinciplesPage()),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: SettingsPage()),
        ),
      ],
    ),
  ],
);
