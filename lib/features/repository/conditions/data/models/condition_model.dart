import 'package:zim_herbs_repo/core/utils/enums.dart';
import '../../domain/entities/condition.dart';

/// Data layer model representing the `conditions` table in Supabase.
class ConditionModel {
  final String id;
  final String name;
  final BodySystem bodySystem;
  final String? description;
  final List<String> symptoms;
  final List<String> precautions;

  ConditionModel({
    required this.id,
    required this.name,
    required this.bodySystem,
    this.description,
    this.symptoms = const [],
    this.precautions = const [],
  });

  /// Factory constructor to parse JSON from Supabase.
  factory ConditionModel.fromJson(Map<String, dynamic> json) {
    return ConditionModel(
      id: json['id'] as String,
      name: json['name'] as String,
      bodySystem: bodySystemFromString(json['body_system']),
      description: json['description'] as String?,
      symptoms: (json['symptoms'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      precautions: (json['precautions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
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
    );
  }
}
