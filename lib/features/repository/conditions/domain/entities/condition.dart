import 'package:zim_herbs_repo/core/utils/enums.dart';
import 'body_part.dart';

/// Pure domain entity representing a Condition.
/// Independent of database or serialization.
class Condition {
  final String id;
  final String name;
  final BodySystem bodySystem;
  final String? description;
  final List<String> symptoms;
  final List<String> precautions;
  final List<BodyPart> bodyParts;

  const Condition({
    required this.id,
    required this.name,
    required this.bodySystem,
    this.description,
    this.symptoms = const [],
    this.precautions = const [],
    this.bodyParts = const [],
  });

  String get displayName => name;
}
