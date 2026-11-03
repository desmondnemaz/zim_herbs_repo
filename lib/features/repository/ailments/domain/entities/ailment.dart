import 'package:zim_herbs_repo/core/utils/enums.dart';
import 'body_part.dart';

/// Pure domain entity representing an Ailment.
/// Independent of database or serialization.
class Ailment {
  final String id;
  final String name;
  final AilmentCategory ailmentCategory;
  final String? description;
  final List<String> symptoms;
  final List<String> precautions;
  final List<BodyPart> bodyParts;

  const Ailment({
    required this.id,
    required this.name,
    AilmentCategory? ailmentCategory,
    AilmentCategory? bodySystem,
    this.description,
    this.symptoms = const [],
    this.precautions = const [],
    this.bodyParts = const [],
  }) : ailmentCategory =
            ailmentCategory ?? bodySystem ?? AilmentCategory.heartBlood;

  /// Backward-compatible alias
  AilmentCategory get bodySystem => ailmentCategory;

  String get displayName => name;

  Ailment copyWith({
    String? id,
    String? name,
    AilmentCategory? ailmentCategory,
    String? description,
    List<String>? symptoms,
    List<String>? precautions,
    List<BodyPart>? bodyParts,
  }) {
    return Ailment(
      id: id ?? this.id,
      name: name ?? this.name,
      ailmentCategory: ailmentCategory ?? this.ailmentCategory,
      description: description ?? this.description,
      symptoms: symptoms ?? this.symptoms,
      precautions: precautions ?? this.precautions,
      bodyParts: bodyParts ?? this.bodyParts,
    );
  }
}

/// Backward-compatible alias for legacy Condition references
typedef Condition = Ailment;
