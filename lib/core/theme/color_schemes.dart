import 'package:flutter/material.dart';

class AppColorScheme {
  final String id;
  final String name;
  final Color primary;
  final Color accent;

  const AppColorScheme({
    required this.id,
    required this.name,
    required this.primary,
    required this.accent,
  });
}

const List<AppColorScheme> appColorSchemes = [
  AppColorScheme(
    id: 'deep_blue',
    name: '深海蓝',
    primary: Color(0xFF3F51B5),
    accent: Color(0xFFFFC107),
  ),
  AppColorScheme(
    id: 'forest_green',
    name: '森林绿',
    primary: Color(0xFF2E7D32),
    accent: Color(0xFFA5D6A7),
  ),
  AppColorScheme(
    id: 'sunset_orange',
    name: '日落橙',
    primary: Color(0xFFE65100),
    accent: Color(0xFFFFCC02),
  ),
];

AppColorScheme colorSchemeById(String id) {
  return appColorSchemes.firstWhere(
    (scheme) => scheme.id == id,
    orElse: () => appColorSchemes.first,
  );
}
