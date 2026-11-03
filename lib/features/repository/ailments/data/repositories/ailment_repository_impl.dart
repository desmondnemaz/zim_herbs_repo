import 'package:zim_herbs_repo/core/utils/enums.dart';
import '../../domain/entities/ailment.dart';
import '../../domain/entities/body_part.dart';
import '../../domain/repositories/ailment_repository.dart';
import '../datasources/ailment_remote_datasource.dart';
import '../models/ailment_model.dart';
import '../models/body_part_model.dart';

class AilmentRepositoryImpl implements AilmentRepository {
  final AilmentRemoteDataSource dataSource;

  AilmentRepositoryImpl(this.dataSource);

  @override
  Future<List<Ailment>> getAllAilments() async {
    final models = await dataSource.getAllAilments();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<int> getAilmentsCount() {
    return dataSource.getAilmentsCount();
  }

  @override
  Future<Ailment?> getAilmentById(String id) async {
    final model = await dataSource.getAilmentById(id);
    return model?.toEntity();
  }

  @override
  Future<List<Ailment>> getAilmentsByCategory(
    AilmentCategory ailmentCategory,
  ) async {
    final models = await dataSource.getAilmentsByCategory(ailmentCategory);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<Ailment>> getAilmentsByBodyPart(String bodyPartId) async {
    final models = await dataSource.getAilmentsByBodyPart(bodyPartId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<Ailment>> searchAilments(String query) async {
    final models = await dataSource.searchAilments(query);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Ailment> createAilment(
    Ailment ailment, {
    List<String>? bodyPartIds,
  }) async {
    final model = AilmentModel.fromEntity(ailment);
    final createdModel = await dataSource.createAilment(
      model,
      bodyPartIds: bodyPartIds,
    );
    return createdModel.toEntity();
  }

  @override
  Future<Ailment> updateAilment(
    Ailment ailment, {
    List<String>? bodyPartIds,
  }) async {
    final model = AilmentModel.fromEntity(ailment);
    final updatedModel = await dataSource.updateAilment(
      model,
      bodyPartIds: bodyPartIds,
    );
    return updatedModel.toEntity();
  }

  @override
  Future<void> deleteAilment(String id) {
    return dataSource.deleteAilment(id);
  }

  @override
  Future<List<BodyPart>> getAllBodyParts() async {
    final models = await dataSource.getAllBodyParts();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<BodyPart?> getBodyPartById(String id) async {
    final model = await dataSource.getBodyPartById(id);
    return model?.toEntity();
  }

  @override
  Future<BodyPart> createBodyPart(BodyPart bodyPart) async {
    final model = BodyPartModel.fromEntity(bodyPart);
    final createdModel = await dataSource.createBodyPart(model);
    return createdModel.toEntity();
  }

  @override
  Future<BodyPart> updateBodyPart(BodyPart bodyPart) async {
    final model = BodyPartModel.fromEntity(bodyPart);
    final updatedModel = await dataSource.updateBodyPart(model);
    return updatedModel.toEntity();
  }

  @override
  Future<void> deleteBodyPart(String id) {
    return dataSource.deleteBodyPart(id);
  }

  // ============================================================
  // BACKWARD-COMPATIBLE OVERRIDES
  // ============================================================
  @override
  Future<List<Ailment>> getAllConditions() => getAllAilments();

  @override
  Future<int> getConditionsCount() => getAilmentsCount();

  @override
  Future<Ailment?> getConditionById(String id) => getAilmentById(id);

  @override
  Future<List<Ailment>> getConditionsByAilmentCategory(
    AilmentCategory ailmentCategory,
  ) =>
      getAilmentsByCategory(ailmentCategory);

  @override
  Future<List<Ailment>> getConditionsByBodySystem(BodySystem bodySystem) =>
      getAilmentsByCategory(bodySystem);

  @override
  Future<List<Ailment>> getConditionsByBodyPart(String bodyPartId) =>
      getAilmentsByBodyPart(bodyPartId);

  @override
  Future<List<Ailment>> searchConditions(String query) =>
      searchAilments(query);

  @override
  Future<Ailment> createCondition(
    Ailment condition, {
    List<String>? bodyPartIds,
  }) =>
      createAilment(condition, bodyPartIds: bodyPartIds);

  @override
  Future<Ailment> updateCondition(
    Ailment condition, {
    List<String>? bodyPartIds,
  }) =>
      updateAilment(condition, bodyPartIds: bodyPartIds);

  @override
  Future<void> deleteCondition(String id) => deleteAilment(id);
}

/// Backward-compatible alias for legacy ConditionRepositoryImpl
typedef ConditionRepositoryImpl = AilmentRepositoryImpl;
