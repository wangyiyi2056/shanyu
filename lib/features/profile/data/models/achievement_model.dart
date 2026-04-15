import 'package:flutter/material.dart';

/// 成就徽章模型
class Achievement {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final bool isUnlocked;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    this.isUnlocked = false,
  });

  Achievement copyWith({bool? isUnlocked}) => Achievement(
        id: id,
        name: name,
        description: description,
        icon: icon,
        color: color,
        isUnlocked: isUnlocked ?? this.isUnlocked,
      );
}
