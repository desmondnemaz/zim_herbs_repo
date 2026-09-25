import 'package:zim_herbs_repo/core/utils/enums.dart';
import '../../domain/entities/condition.dart';
import 'body_part_model.dart';

/// Data layer model representing the `conditions` table in Supabase.
class ConditionModel {
  final String id;
  final String name;
  final BodySystem bodySystem;
  final String? description;
  final List<String> symptoms;
  final List<String> precautions;
  final List<BodyPartModel> bodyParts;

  ConditionModel({
    required this.id,
    required this.name,
    required this.bodySystem,
    this.description,
    this.symptoms = const [],
    this.precautions = const [],
    this.bodyParts = const [],
  });

  /// Factory constructor to parse JSON from Supabase.
  factory ConditionModel.fromJson(Map<String, dynamic> json) {
    final rawConditionBodyParts =
        json['condition_body_parts'] as List<dynamic>?;
    final List<BodyPartModel> parsedBodyParts = [];

    if (rawConditionBodyParts != null) {
      for (final item in rawConditionBodyParts) {
        if (item is Map<String, dynamic>) {
          if (item['body_parts'] != null &&
              item['body_parts'] is Map<String, dynamic>) {
            parsedBodyParts.add(
              BodyPartModel.fromJson(
                item['body_parts'] as Map<String, dynamic>,
              ),
            );
          } else if (item['name_en'] != null) {
            parsedBodyParts.add(BodyPartModel.fromJson(item));
          }
        }
      }
    }

    return ConditionModel(
      id: json['id'] as String,
      name: json['name'] as String,
      bodySystem: bodySystemFromString(json['body_system'] ?? ''),
      description: json['description'] as String?,
      symptoms: (json['symptoms'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      precautions: (json['precautions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      bodyParts: parsedBodyParts,
    );
  }

  /// Convert model to JSON for insert/update in Supabase.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'body_system': bodySystemToString(bodySystem),
      'description': description,
      'symptoms': symptoms,
      'precautions': precautions,
    };
  }

  /// Convert Data Model to Domain Entity.
  Condition toEntity() {
    return Condition(
      id: id,
      name: name,
      bodySystem: bodySystem,
      description: description,
      symptoms: symptoms,
      precautions: precautions,
      bodyParts: bodyParts.map((bp) => bp.toEntity()).toList(),
    );
  }

  /// Convert Domain Entity to Data Model.
  factory ConditionModel.fromEntity(Condition condition) {
    return ConditionModel(
      id: condition.id,
      name: condition.name,
      bodySystem: condition.bodySystem,
      description: condition.description,
      symptoms: condition.symptoms,
      precautions: condition.precautions,
      bodyParts: condition.bodyParts
          .map((bp) => BodyPartModel.fromEntity(bp))
          .toList(),
    );
  }
}
