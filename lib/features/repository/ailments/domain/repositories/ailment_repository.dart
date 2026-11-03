import 'package:zim_herbs_repo/core/utils/enums.dart';
import '../entities/ailment.dart';
import '../entities/body_part.dart';

/// Contract defining all ailment and body parts repository operations in the Domain layer.
abstract class AilmentRepository {
  /// Get all ailments with associated body parts.
  Future<List<Ailment>> getAllAilments();

  /// Get total count of ailments.
  Future<int> getAilmentsCount();

  /// Get a single ailment by its ID.
  Future<Ailment?> getAilmentById(String id);

  /// Get ailments filtered by a specific category.
  Future<List<Ailment>> getAilmentsByCategory(AilmentCategory ailmentCategory);

  /// Get ailments filtered by a specific body part.
  Future<List<Ailment>> getAilmentsByBodyPart(String bodyPartId);

  /// Search ailments by name.
  Future<List<Ailment>> searchAilments(String query);

  /// Create a new ailment, optionally specifying body part IDs to link.
  Future<Ailment> createAilment(
    Ailment ailment, {
    List<String>? bodyPartIds,
  });

  /// Update an existing ailment, optionally updating linked body part IDs.
  Future<Ailment> updateAilment(
    Ailment ailment, {
    List<String>? bodyPartIds,
  });

  /// Delete an ailment.
  Future<void> deleteAilment(String id);

  /// Get all available body parts.
  Future<List<BodyPart>> getAllBodyParts();

  /// Get a single body part by ID.
  Future<BodyPart?> getBodyPartById(String id);

  /// Create a new body part.
  Future<BodyPart> createBodyPart(BodyPart bodyPart);

  /// Update an existing body part.
  Future<BodyPart> updateBodyPart(BodyPart bodyPart);

  /// Delete a body part.
  Future<void> deleteBodyPart(String id);

  // ============================================================
  // BACKWARD-COMPATIBLE ALIASES
  // ============================================================
  Future<List<Ailment>> getAllConditions() => getAllAilments();
  Future<int> getConditionsCount() => getAilmentsCount();
  Future<Ailment?> getConditionById(String id) => getAilmentById(id);
  Future<List<Ailment>> getConditionsByAilmentCategory(AilmentCategory cat) =>
      getAilmentsByCategory(cat);
  Future<List<Ailment>> getConditionsByBodySystem(BodySystem sys) =>
      getAilmentsByCategory(sys);
  Future<List<Ailment>> getConditionsByBodyPart(String bpId) =>
      getAilmentsByBodyPart(bpId);
  Future<List<Ailment>> searchConditions(String q) => searchAilments(q);
  Future<Ailment> createCondition(Ailment a, {List<String>? bodyPartIds}) =>
      createAilment(a, bodyPartIds: bodyPartIds);
  Future<Ailment> updateCondition(Ailment a, {List<String>? bodyPartIds}) =>
      updateAilment(a, bodyPartIds: bodyPartIds);
  Future<void> deleteCondition(String id) => deleteAilment(id);
}

/// Backward-compatible alias for legacy ConditionRepository
typedef ConditionRepository = AilmentRepository;
