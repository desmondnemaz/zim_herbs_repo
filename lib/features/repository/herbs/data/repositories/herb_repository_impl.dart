import 'dart:typed_data';

import '../../domain/entities/herb.dart';
import '../datasources/herb_remote_datasource.dart';
import '../models/herb_model.dart';
import '../../domain/repositories/herb_repository.dart';

class HerbRepositoryImpl implements HerbRepository {
  final HerbRemoteDataSource dataSource;

  HerbRepositoryImpl(this.dataSource);

  @override
Future<List<Herb>> getAllHerbs() async {
  final herbs = await dataSource.getAllHerbs();

  return herbs.map((herb) => herb.toEntity()).toList();
}

  @override
Future<List<Herb>> getLatestHerbs({
  int limit = 5,
}) async {
  final herbs = await dataSource.getLatestHerbs(
    limit: limit,
  );

  return herbs.map((herb) => herb.toEntity()).toList();
}

  @override
Future<List<Herb>> getTrendingHerbs({
  int limit = 5,
}) async {
  final herbs = await dataSource.getTrendingHerbs(
    limit: limit,
  );

  return herbs.map((herb) => herb.toEntity()).toList();
}

  @override
  Future<int> getHerbsCount() {
    return dataSource.getHerbsCount();
  }

 @override
Future<Herb?> getHerbById(String id) async {
  final herb = await dataSource.getHerbById(id);

  return herb?.toEntity();
}

  @override
Future<List<Herb>> searchHerbs(String query) async {
  final herbs = await dataSource.searchHerbs(query);

  return herbs.map((herb) => herb.toEntity()).toList();
}

  @override
 Future<List<Herb>> getHerbsByCondition(
  String conditionId,
) async {
  final herbs = await dataSource.getHerbsByCondition(
    conditionId,
  );

  return herbs.map((herb) => herb.toEntity()).toList();
}

  

  @override
  Future<String> uploadHerbImage(
    String herbId,
    String fileName,
    Uint8List bytes,
  ) {
    return dataSource.uploadHerbImage(
      herbId,
      fileName,
      bytes,
    );
  }

  @override
  Future<Herb> createHerb(Herb herb) async {
  final model = HerbModel.fromEntity(herb);

  final createdModel = await dataSource.createHerb(model);

  return createdModel.toEntity();
}

  @override
Future<Herb> updateHerb(
  Herb herb,
) async {
  final model = HerbModel.fromEntity(herb);

  final updatedModel = await dataSource.updateHerb(
    model,
  );

  return updatedModel.toEntity();
}

  @override
  Future<void> deleteHerb(String id) {
    return dataSource.deleteHerb(id);
  }
}