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
    primary: Color(0xFF1A237E),
    accent: Color(0xFFFFD54F),
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
  AppColorScheme(
    id: 'lavender',
    name: '薰衣草紫',
    primary: Color(0xFF6A1B9A),
    accent: Color(0xFFCE93D8),
  ),
  AppColorScheme(
    id: 'ocean_teal',
    name: '海洋青',
    primary: Color(0xFF00695C),
    accent: Color(0xFF80CBC4),
  ),
  AppColorScheme(
    id: 'warm_brown',
    name: '暖木棕',
    primary: Color(0xFF4E342E),
    accent: Color(0xFFBCAAA4),
  ),
];
