import 'body_part_model.dart';

/// Data layer model representing the `ailment_body_parts` (formerly `condition_body_parts`) junction table in Supabase.
class AilmentBodyPartModel {
  final String ailmentId;
  final String bodyPartId;
  final DateTime? createdAt;
  final BodyPartModel? bodyPart;

  AilmentBodyPartModel({
    required this.ailmentId,
    required this.bodyPartId,
    this.createdAt,
    this.bodyPart,
  });

  /// Backward-compatible alias
  String get conditionId => ailmentId;

  /// Factory constructor to parse JSON from Supabase.
  factory AilmentBodyPartModel.fromJson(Map<String, dynamic> json) {
    return AilmentBodyPartModel(
      ailmentId: (json['ailment_id'] ?? json['condition_id'] ?? '') as String,
      bodyPartId: (json['body_part_id'] ?? '') as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      bodyPart: json['body_parts'] != null
          ? BodyPartModel.fromJson(json['body_parts'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Convert model to JSON for Supabase insert.
  Map<String, dynamic> toJson() {
    return {
      'ailment_id': ailmentId,
      'body_part_id': bodyPartId,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}

/// Backward-compatible alias for legacy ConditionBodyPartModel
typedef ConditionBodyPartModel = AilmentBodyPartModel;
