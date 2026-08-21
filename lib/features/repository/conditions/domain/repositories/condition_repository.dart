import 'package:zim_herbs_repo/core/utils/enums.dart';
import '../entities/condition.dart';

/// Contract defining all condition repository operations in the Domain layer.
abstract class ConditionRepository {
  /// Get all conditions.
  Future<List<Condition>> getAllConditions();

  /// Get total count of conditions.
  Future<int> getConditionsCount();

  /// Get a single condition by its ID.
  Future<Condition?> getConditionById(String id);

  /// Get conditions filtered by a specific body system.
  Future<List<Condition>> getConditionsByBodySystem(BodySystem bodySystem);

  /// Search conditions by name.
  Future<List<Condition>> searchConditions(String query);

  /// Create a new condition.
  Future<Condition> createCondition(Condition condition);

  /// Update an existing condition.
  Future<Condition> updateCondition(Condition condition);

  /// Delete a condition.
  Future<void> deleteCondition(String id);
}
