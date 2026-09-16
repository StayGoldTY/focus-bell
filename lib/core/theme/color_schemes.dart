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
  AppColorScheme(
    id: 'lavender',
    name: '薰衣草紫',
    primary: Color(0xFF7B1FA2),
    accent: Color(0xFFE1BEE7),
  ),
  AppColorScheme(
    id: 'ocean_teal',
    name: '海洋青',
    primary: Color(0xFF00897B),
    accent: Color(0xFF80CBC4),
  ),
  AppColorScheme(
    id: 'warm_brown',
    name: '暖木棕',
    primary: Color(0xFF6D4C41),
    accent: Color(0xFFD7CCC8),
  ),
];
