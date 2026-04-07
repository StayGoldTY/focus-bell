import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/timer/providers/settings_provider.dart';

class FocusBellApp extends ConsumerWidget {
  const FocusBellApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final colorScheme = ref.watch(colorSchemeProvider);

    return MaterialApp.router(
      title: 'FocusBell',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light(colorScheme),
      darkTheme: AppTheme.dark(colorScheme),
      routerConfig: appRouter,
    );
  }
}
