import '../../domain/entities/body_part.dart';

/// Data layer model representing the `body_parts` table in Supabase.
class BodyPartModel {
  final String id;
  final String? code;
  final String nameEn;
  final String? nameSn;
  final String? nameNd;
  final String? description;
  final String? iconUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BodyPartModel({
    required this.id,
    this.code,
    required this.nameEn,
    this.nameSn,
    this.nameNd,
    this.description,
    this.iconUrl,
    this.createdAt,
    this.updatedAt,
  });

  /// Factory constructor to parse JSON from Supabase.
  factory BodyPartModel.fromJson(Map<String, dynamic> json) {
    return BodyPartModel(
      id: json['id'] as String,
      code: json['code'] as String?,
      nameEn: (json['name_en'] ?? json['name'] ?? '') as String,
      nameSn: json['name_sn'] as String?,
      nameNd: json['name_nd'] as String?,
      description: json['description'] as String?,
      iconUrl: json['icon_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert model to JSON for insert/update in Supabase.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (code != null) 'code': code,
      'name_en': nameEn,
      if (nameSn != null) 'name_sn': nameSn,
      if (nameNd != null) 'name_nd': nameNd,
      if (description != null) 'description': description,
      if (iconUrl != null) 'icon_url': iconUrl,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  /// Convert Data Model to Domain Entity.
  BodyPart toEntity() {
    return BodyPart(
      id: id,
      code: code,
      nameEn: nameEn,
      nameSn: nameSn,
      nameNd: nameNd,
      description: description,
      iconUrl: iconUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Convert Domain Entity to Data Model.
  factory BodyPartModel.fromEntity(BodyPart entity) {
    return BodyPartModel(
      id: entity.id,
      code: entity.code,
      nameEn: entity.nameEn,
      nameSn: entity.nameSn,
      nameNd: entity.nameNd,
      description: entity.description,
      iconUrl: entity.iconUrl,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
