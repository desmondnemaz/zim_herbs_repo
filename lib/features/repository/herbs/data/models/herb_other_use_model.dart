import 'package:zim_herbs_repo/features/repository/herbs/domain/entities/herb_other_use.dart';

/// Data model representing a row in `public.herb_other_uses`.
class HerbOtherUseModel {
  final String id;
  final String herbId;
  final String category;
  final String? title;
  final String description;
  final DateTime? createdAt;
  final String? createdBy;
  final DateTime? updatedAt;
  final String? updatedBy;

  const HerbOtherUseModel({
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

  factory HerbOtherUseModel.fromJson(Map<String, dynamic> json) {
    return HerbOtherUseModel(
      id: json['id'] as String,
      herbId: json['herb_id'] as String,
      category: json['category'] as String,
      title: json['title'] as String?,
      description: json['description'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      createdBy: json['created_by'] as String?,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      updatedBy: json['updated_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'herb_id': herbId,
      'category': category,
      if (title != null) 'title': title,
      'description': description,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (createdBy != null) 'created_by': createdBy,
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (updatedBy != null) 'updated_by': updatedBy,
    };
  }

  HerbOtherUse toEntity() {
    return HerbOtherUse(
      id: id,
      herbId: herbId,
      category: category,
      title: title,
      description: description,
      createdAt: createdAt,
      createdBy: createdBy,
      updatedAt: updatedAt,
      updatedBy: updatedBy,
    );
  }

  factory HerbOtherUseModel.fromEntity(HerbOtherUse entity) {
    return HerbOtherUseModel(
      id: entity.id,
      herbId: entity.herbId,
      category: entity.category,
      title: entity.title,
      description: entity.description,
      createdAt: entity.createdAt,
      createdBy: entity.createdBy,
      updatedAt: entity.updatedAt,
      updatedBy: entity.updatedBy,
    );
  }
}
