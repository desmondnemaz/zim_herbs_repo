import 'body_part_model.dart';

/// Data layer model representing the `condition_body_parts` junction table in Supabase.
class ConditionBodyPartModel {
  final String conditionId;
  final String bodyPartId;
  final DateTime? createdAt;
  final BodyPartModel? bodyPart;

  ConditionBodyPartModel({
    required this.conditionId,
    required this.bodyPartId,
    this.createdAt,
    this.bodyPart,
  });

  /// Factory constructor to parse JSON from Supabase.
  factory ConditionBodyPartModel.fromJson(Map<String, dynamic> json) {
    return ConditionBodyPartModel(
      conditionId: (json['condition_id'] ?? '') as String,
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
      'condition_id': conditionId,
      'body_part_id': bodyPartId,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}
