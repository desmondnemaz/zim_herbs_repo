import '../../domain/entities/remedy.dart';
import '../../domain/repositories/remedy_repository.dart';
import '../datasources/remedy_remote_datasource.dart';
import '../models/remedy_model.dart';

/// Concrete implementation of [RemedyRepository].
///
/// Bridges the DATA layer (RemedyRemoteDataSource)
/// and the DOMAIN layer (Remedy entities).
class RemedyRepositoryImpl implements RemedyRepository {
  final RemedyRemoteDataSource dataSource;

  RemedyRepositoryImpl(this.dataSource);

  @override
  Future<List<Remedy>> getAllRemedies() async {
    final models = await dataSource.getAllRemedies();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Remedy?> getRemedyById(String id) async {
    final model = await dataSource.getRemedyById(id);
    return model?.toEntity();
  }

  @override
  Future<List<Remedy>> searchRemedies(String query) async {
    final models = await dataSource.searchRemedies(query);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<Remedy>> getRemediesByCondition(String conditionId) async {
    final models = await dataSource.getRemediesByCondition(conditionId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<Remedy>> getRemediesByHerbId(String herbId) async {
    final models = await dataSource.getRemediesByHerbId(herbId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<int> getRemediesCount() {
    return dataSource.getRemediesCount();
  }

  @override
  Future<Remedy> createRemedy(Remedy remedy) async {
    final model = RemedyModel.fromEntity(remedy);
    final created = await dataSource.createRemedy(
      model,
      model.remedyHerbs,
    );
    return created.toEntity();
  }

  @override
  Future<Remedy> updateRemedy(Remedy remedy) async {
    final model = RemedyModel.fromEntity(remedy);
    final updated = await dataSource.updateRemedy(model);
    return updated.toEntity();
  }

  @override
  Future<void> deleteRemedy(String id) {
    return dataSource.deleteRemedy(id);
  }

  @override
  Future<void> approveRemedy(String id, {bool approved = true}) {
    return dataSource.approveRemedy(id, approved: approved);
  }
}
