import '../../domain/entities/treatment.dart';
import '../../domain/repositories/treatment_repository.dart';
import '../datasources/treatment_remote_datasource.dart';
import '../models/treatment_model.dart';

/// Concrete implementation of [TreatmentRepository].
///
/// Bridges the DATA layer (TreatmentRemoteDataSource)
/// and the DOMAIN layer (Treatment entities).
class TreatmentRepositoryImpl implements TreatmentRepository {
  final TreatmentRemoteDataSource dataSource;

  TreatmentRepositoryImpl(this.dataSource);

  @override
  Future<List<Treatment>> getAllTreatments() async {
    final models = await dataSource.getAllTreatments();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Treatment?> getTreatmentById(String id) async {
    final model = await dataSource.getTreatmentById(id);
    return model?.toEntity();
  }

  @override
  Future<List<Treatment>> searchTreatments(String query) async {
    final models = await dataSource.searchTreatments(query);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<Treatment>> getTreatmentsByCondition(String conditionId) async {
    final models = await dataSource.getTreatmentsByCondition(conditionId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<Treatment>> getTreatmentsByHerbId(String herbId) async {
    final models = await dataSource.getTreatmentsByHerbId(herbId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<int> getTreatmentsCount() {
    return dataSource.getTreatmentsCount();
  }

  @override
  Future<Treatment> createTreatment(Treatment treatment) async {
    final model = TreatmentModel.fromEntity(treatment);
    final created = await dataSource.createTreatment(
      model,
      model.treatmentHerbs,
    );
    return created.toEntity();
  }

  @override
  Future<Treatment> updateTreatment(Treatment treatment) async {
    final model = TreatmentModel.fromEntity(treatment);
    final updated = await dataSource.updateTreatment(model);
    return updated.toEntity();
  }

  @override
  Future<void> deleteTreatment(String id) {
    return dataSource.deleteTreatment(id);
  }

  @override
  Future<void> approveTreatment(String id, {bool approved = true}) {
    return dataSource.approveTreatment(id, approved: approved);
  }
}
