import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/timer/models/timer_state.dart';
import '../../features/timer/pages/micro_rest_page.dart';
import '../../features/timer/pages/long_break_page.dart';
import '../../features/timer/providers/timer_provider.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _navItems = [
    (icon: Icons.timer_rounded, activeIcon: Icons.timer_rounded, label: '专注'),
    (icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart_rounded, label: '统计'),
    (icon: Icons.school_outlined, activeIcon: Icons.school_rounded, label: '科学'),
    (icon: Icons.settings_outlined, activeIcon: Icons.settings_rounded, label: '设置'),
  ];

  static const _routes = ['/timer', '/statistics', '/principles', '/settings'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(timerProvider);
    final currentIndex = _calculateIndex(GoRouterState.of(context).uri.path);

    // 微休息全屏覆盖
    if (timerState.phase == TimerPhase.microRest) {
      return const MicroRestOverlay();
    }

    // 大休息全屏覆盖
    if (timerState.phase == TimerPhase.longBreak) {
      return const LongBreakOverlay();
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          context.go(_routes[index]);
        },
        destinations: _navItems
            .map((item) => NavigationDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.activeIcon),
                  label: item.label,
                ))
            .toList(),
      ),
    );
  }

  int _calculateIndex(String path) {
    final index = _routes.indexOf(path);
    return index >= 0 ? index : 0;
  }
}
