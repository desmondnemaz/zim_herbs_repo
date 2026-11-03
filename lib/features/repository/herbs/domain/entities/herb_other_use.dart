import 'package:flutter/material.dart';

/// Represents a non-medicinal traditional, practical, or cultural use of a herb.
class HerbOtherUse {
  final String id;
  final String herbId;
  final String category;
  final String? title;
  final String description;
  final DateTime? createdAt;
  final String? createdBy;
  final DateTime? updatedAt;
  final String? updatedBy;

  const HerbOtherUse({
    required this.id,
    required this.herbId,
    required this.category,
    this.title,
    required this.description,
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
  });

  /// Human-friendly display label for the use category.
  String get categoryLabel {
    switch (category) {
      case 'food_nutrition':
        return 'Food & Nutrition';
      case 'construction_fencing':
        return 'Construction & Fencing';
      case 'firewood':
        return 'Firewood & Fuel';
      case 'cultural_spiritual':
        return 'Cultural & Spiritual';
      case 'ritual':
        return 'Ritual Uses';
      case 'crafts_tools':
        return 'Crafts & Practical Tools';
      case 'veterinary':
        return 'Veterinary & Animal Care';
      default:
        return 'Other Traditional Use';
    }
  }

  /// Theme icon for the category.
  IconData get categoryIcon {
    switch (category) {
      case 'food_nutrition':
        return Icons.restaurant_rounded;
      case 'construction_fencing':
        return Icons.fence_rounded;
      case 'firewood':
        return Icons.local_fire_department_rounded;
      case 'cultural_spiritual':
        return Icons.auto_awesome_rounded;
      case 'ritual':
        return Icons.self_improvement_rounded;
      case 'crafts_tools':
        return Icons.handyman_rounded;
      case 'veterinary':
        return Icons.pets_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  HerbOtherUse copyWith({
    String? id,
    String? herbId,
    String? category,
    String? title,
    String? description,
    DateTime? createdAt,
    String? createdBy,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return HerbOtherUse(
      id: id ?? this.id,
      herbId: herbId ?? this.herbId,
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}
