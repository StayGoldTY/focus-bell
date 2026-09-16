import 'package:flutter/material.dart';

class FocusTaskCategory {
  final String id;
  final String label;
  final String description;
  final IconData icon;

  const FocusTaskCategory({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
  });
}

const List<FocusTaskCategory> focusTaskCategories = [
  FocusTaskCategory(
    id: 'study',
    label: '学习',
    description: '看课、背诵、刷题',
    icon: Icons.menu_book_rounded,
  ),
  FocusTaskCategory(
    id: 'coding',
    label: '编程',
    description: '开发、调试、排查问题',
    icon: Icons.code_rounded,
  ),
  FocusTaskCategory(
    id: 'writing',
    label: '写作',
    description: '写文档、方案、内容创作',
    icon: Icons.edit_note_rounded,
  ),
  FocusTaskCategory(
    id: 'reading',
    label: '阅读',
    description: '读书、精读、做摘录',
    icon: Icons.auto_stories_rounded,
  ),
  FocusTaskCategory(
    id: 'review',
    label: '复盘',
    description: '总结、回顾、整理思路',
    icon: Icons.insights_rounded,
  ),
  FocusTaskCategory(
    id: 'other',
    label: '其他',
    description: '未分类的专注任务',
    icon: Icons.flag_rounded,
  ),
];

FocusTaskCategory? findFocusTaskCategoryById(String? id) {
  if (id == null || id.isEmpty) {
    return null;
  }

  for (final category in focusTaskCategories) {
    if (category.id == id) {
      return category;
    }
  }

  return null;
}
