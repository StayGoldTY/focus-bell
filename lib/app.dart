import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/timer/models/timer_state.dart';
import 'features/timer/providers/settings_provider.dart';
import 'features/timer/providers/timer_provider.dart';

class FocusBellApp extends ConsumerWidget {
  const FocusBellApp({super.key});

  static const _webMaxWidth = 480.0;
  static const _webBgLight = Color(0xFFECEAF4);
  static const _webBgDark = Color(0xFF1C1B1F);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final colorScheme = ref.watch(colorSchemeProvider);
    final timerPhase = ref.watch(timerProvider.select((state) => state.phase));

    return MaterialApp.router(
      title: 'FocusBell',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light(colorScheme),
      darkTheme: AppTheme.dark(colorScheme),
      routerConfig: appRouter,
      builder: (context, child) {
        if (child == null || !kIsWeb || _usesFullscreenShell(timerPhase)) {
          return child ?? const SizedBox.shrink();
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth <= _webMaxWidth) {
              return child;
            }

            final mediaQuery = MediaQuery.of(context);
            final brightness = Theme.of(context).brightness;
            final bgColor = brightness == Brightness.dark
                ? _webBgDark
                : _webBgLight;

            return ColoredBox(
              color: bgColor,
              child: Align(
                alignment: Alignment.topCenter,
                child: MediaQuery(
                  data: mediaQuery.copyWith(
                    size: Size(_webMaxWidth, mediaQuery.size.height),
                  ),
                  child: SizedBox(
                    width: _webMaxWidth,
                    height: constraints.maxHeight,
                    child: child,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  static bool _usesFullscreenShell(TimerPhase phase) =>
      phase == TimerPhase.microRest || phase == TimerPhase.longBreak;
}
