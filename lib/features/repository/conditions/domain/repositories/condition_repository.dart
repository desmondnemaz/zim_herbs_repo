import 'package:zim_herbs_repo/core/utils/enums.dart';
import '../entities/body_part.dart';
import '../entities/condition.dart';

/// Contract defining all condition and body parts repository operations in the Domain layer.
abstract class ConditionRepository {
  /// Get all conditions with associated body parts.
  Future<List<Condition>> getAllConditions();

  /// Get total count of conditions.
  Future<int> getConditionsCount();

  /// Get a single condition by its ID.
  Future<Condition?> getConditionById(String id);

  /// Get conditions filtered by a specific body system.
  Future<List<Condition>> getConditionsByBodySystem(BodySystem bodySystem);

  /// Get conditions filtered by a specific body part.
  Future<List<Condition>> getConditionsByBodyPart(String bodyPartId);

  /// Search conditions by name.
  Future<List<Condition>> searchConditions(String query);

  /// Create a new condition, optionally specifying body part IDs to link.
  Future<Condition> createCondition(
    Condition condition, {
    List<String>? bodyPartIds,
  });

  /// Update an existing condition, optionally updating linked body part IDs.
  Future<Condition> updateCondition(
    Condition condition, {
    List<String>? bodyPartIds,
  });

  /// Delete a condition.
  Future<void> deleteCondition(String id);

  /// Get all available body parts.
  Future<List<BodyPart>> getAllBodyParts();

  /// Get a single body part by ID.
  Future<BodyPart?> getBodyPartById(String id);
}
