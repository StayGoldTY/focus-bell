import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../features/timer/models/timer_state.dart';
import '../../features/timer/pages/long_break_page.dart';
import '../../features/timer/pages/micro_rest_page.dart';
import '../../features/timer/providers/timer_provider.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _navItems = [
    (icon: Icons.timer_outlined, activeIcon: Icons.timer_rounded, label: '专注'),
    (
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart_rounded,
      label: '统计',
    ),
    (
      icon: Icons.school_outlined,
      activeIcon: Icons.school_rounded,
      label: '科学',
    ),
    (
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
      label: '设置',
    ),
  ];

  static const _routes = ['/timer', '/statistics', '/principles', '/settings'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(timerProvider);
    final endPromptOpen = ref.watch(sessionEndPromptOpenProvider);
    final currentIndex = _calculateIndex(GoRouterState.of(context).uri.path);
    final bottomClearance =
        AppConstants.shellNavClearance + MediaQuery.paddingOf(context).bottom;

    if (timerState.phase == TimerPhase.longBreak) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) {
          return;
        }
        Navigator.of(
          context,
          rootNavigator: true,
        ).popUntil((route) => route is! PopupRoute);
      });
    }

    if (timerState.phase == TimerPhase.microRest && !endPromptOpen) {
      return const MicroRestOverlay();
    }

    if (timerState.phase == TimerPhase.longBreak) {
      return const LongBreakOverlay();
    }

    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Padding(
        padding: EdgeInsets.only(bottom: bottomClearance),
        child: child,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.45),
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: NavigationBar(
              selectedIndex: currentIndex,
              onDestinationSelected: (index) {
                context.go(_routes[index]);
              },
              destinations: _navItems
                  .map(
                    (item) => NavigationDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.activeIcon),
                      label: item.label,
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }

  int _calculateIndex(String path) {
    final index = _routes.indexOf(path);
    return index >= 0 ? index : 0;
  }
}
