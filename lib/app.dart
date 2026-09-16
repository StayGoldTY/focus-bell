import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/timer/models/timer_state.dart';
import 'features/timer/providers/settings_provider.dart';
import 'features/timer/providers/timer_provider.dart';
import 'shared/widgets/focus_atmosphere.dart';

class FocusBellApp extends ConsumerWidget {
  const FocusBellApp({super.key});

  static const _webMaxWidth = 440.0;
  static const _webBgLight = Color(0xFFE7E4F4);
  static const _webBgDark = Color(0xFF141218);

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
        final content = FocusAtmosphere(
          child: child ?? const SizedBox.shrink(),
        );
        if (!kIsWeb || _usesFullscreenShell(timerPhase)) {
          return content;
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth <= _webMaxWidth + 32) {
              return content;
            }

            final mediaQuery = MediaQuery.of(context);
            final brightness = Theme.of(context).brightness;
            final bgColor = brightness == Brightness.dark
                ? _webBgDark
                : _webBgLight;
            final frameHeight = (constraints.maxHeight - 48).clamp(
              520.0,
              constraints.maxHeight,
            );

            return ColoredBox(
              color: bgColor,
              child: Center(
                child: MediaQuery(
                  data: mediaQuery.copyWith(
                    size: Size(_webMaxWidth, frameHeight),
                  ),
                  child: Container(
                    width: _webMaxWidth,
                    height: frameHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.16),
                          blurRadius: 48,
                          offset: const Offset(0, 18),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: content,
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
