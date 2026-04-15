import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/color_schemes.dart';
import '../../../shared/services/storage_service.dart';

/// 主题模式 Provider
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((
  ref,
) {
  final storage = ref.watch(storageServiceProvider);
  return ThemeModeNotifier(storage);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final StorageService _storage;

  ThemeModeNotifier(this._storage) : super(_parseMode(_storage.themeMode));

  static ThemeMode _parseMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final key = mode == ThemeMode.light
        ? 'light'
        : mode == ThemeMode.dark
        ? 'dark'
        : 'system';
    await _storage.setThemeMode(key);
  }
}

/// 配色方案 Provider
final colorSchemeProvider =
    StateNotifierProvider<ColorSchemeNotifier, AppColorScheme>((ref) {
      final storage = ref.watch(storageServiceProvider);
      return ColorSchemeNotifier(storage);
    });

class ColorSchemeNotifier extends StateNotifier<AppColorScheme> {
  final StorageService _storage;

  ColorSchemeNotifier(this._storage)
    : super(
        appColorSchemes.firstWhere(
          (s) => s.id == _storage.colorSchemeId,
          orElse: () => appColorSchemes.first,
        ),
      );

  Future<void> setScheme(AppColorScheme scheme) async {
    state = scheme;
    await _storage.setColorSchemeId(scheme.id);
  }
}
