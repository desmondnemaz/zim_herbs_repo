import 'package:zim_herbs_repo/core/utils/enums.dart';
import '../../domain/entities/ailment.dart';
import 'body_part_model.dart';

/// Data layer model representing the `ailments` (formerly `conditions`) table in Supabase.
class AilmentModel {
  final String id;
  final String name;
  final AilmentCategory ailmentCategory;
  final String? description;
  final List<String> symptoms;
  final List<String> precautions;
  final List<BodyPartModel> bodyParts;

  AilmentModel({
    required this.id,
    required this.name,
    required this.ailmentCategory,
    this.description,
    this.symptoms = const [],
    this.precautions = const [],
    this.bodyParts = const [],
  });

  /// Backward-compatible alias
  AilmentCategory get bodySystem => ailmentCategory;

  /// Factory constructor to parse JSON from Supabase.
  factory AilmentModel.fromJson(Map<String, dynamic> json) {
    final rawAilmentBodyParts =
        (json['ailment_body_parts'] ?? json['condition_body_parts']) as List<dynamic>?;
    final List<BodyPartModel> parsedBodyParts = [];

    if (rawAilmentBodyParts != null) {
      for (final item in rawAilmentBodyParts) {
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

    return AilmentModel(
      id: json['id'] as String,
      name: json['name'] as String,
      ailmentCategory: ailmentCategoryFromString(
        (json['ailment_category'] ?? json['body_system'] ?? '') as String,
      ),
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
      'ailment_category': ailmentCategoryToString(ailmentCategory),
      'description': description,
      'symptoms': symptoms,
      'precautions': precautions,
    };
  }

  /// Convert Data Model to Domain Entity.
  Ailment toEntity() {
    return Ailment(
      id: id,
      name: name,
      ailmentCategory: ailmentCategory,
      description: description,
      symptoms: symptoms,
      precautions: precautions,
      bodyParts: bodyParts.map((bp) => bp.toEntity()).toList(),
    );
  }

  /// Convert Domain Entity to Data Model.
  factory AilmentModel.fromEntity(Ailment ailment) {
    return AilmentModel(
      id: ailment.id,
      name: ailment.name,
      ailmentCategory: ailment.ailmentCategory,
      description: ailment.description,
      symptoms: ailment.symptoms,
      precautions: ailment.precautions,
      bodyParts: ailment.bodyParts
          .map((bp) => BodyPartModel.fromEntity(bp))
          .toList(),
    );
  }
}

/// Backward-compatible alias for legacy ConditionModel references
typedef ConditionModel = AilmentModel;
