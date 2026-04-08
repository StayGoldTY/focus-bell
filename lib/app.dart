import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/timer/providers/settings_provider.dart';

class FocusBellApp extends ConsumerWidget {
  const FocusBellApp({super.key});

  static const _webMaxWidth = 480.0;
  static const _webBgLight = Color(0xFFECEAF4);
  static const _webBgDark = Color(0xFF1C1B1F);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final colorScheme = ref.watch(colorSchemeProvider);

    final app = MaterialApp.router(
      title: 'FocusBell',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light(colorScheme),
      darkTheme: AppTheme.dark(colorScheme),
      routerConfig: appRouter,
    );

    if (!kIsWeb) return app;

    final brightness = WidgetsBinding.instance.platformDispatcher
        .platformBrightness;
    final bgColor = brightness == Brightness.dark ? _webBgDark : _webBgLight;

    return ColoredBox(
      color: bgColor,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _webMaxWidth),
          child: app,
        ),
      ),
    );
  }
}
