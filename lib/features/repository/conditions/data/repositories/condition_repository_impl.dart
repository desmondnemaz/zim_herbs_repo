import 'package:zim_herbs_repo/core/utils/enums.dart';
import '../../domain/entities/condition.dart';
import '../../domain/repositories/condition_repository.dart';
import '../datasources/condition_remote_datasource.dart';
import '../models/condition_model.dart';

class ConditionRepositoryImpl implements ConditionRepository {
  final ConditionRemoteDataSource dataSource;

  ConditionRepositoryImpl(this.dataSource);

  @override
  Future<List<Condition>> getAllConditions() async {
    final models = await dataSource.getAllConditions();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<int> getConditionsCount() {
    return dataSource.getConditionsCount();
  }

  @override
  Future<Condition?> getConditionById(String id) async {
    final model = await dataSource.getConditionById(id);
    return model?.toEntity();
  }

  @override
  Future<List<Condition>> getConditionsByBodySystem(
    BodySystem bodySystem,
  ) async {
    final models = await dataSource.getConditionsByBodySystem(bodySystem);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<Condition>> searchConditions(String query) async {
    final models = await dataSource.searchConditions(query);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Condition> createCondition(Condition condition) async {
    final model = ConditionModel.fromEntity(condition);
    final createdModel = await dataSource.createCondition(model);
    return createdModel.toEntity();
  }

  @override
  Future<Condition> updateCondition(Condition condition) async {
    final model = ConditionModel.fromEntity(condition);
    final updatedModel = await dataSource.updateCondition(model);
    return updatedModel.toEntity();
  }

  @override
  Future<void> deleteCondition(String id) {
    return dataSource.deleteCondition(id);
  }
}
