import 'dart:typed_data';

import '../entities/herb.dart';

/// Defines the operations that the application
/// can perform on herbs.
///
/// This is a DOMAIN contract.
///
/// IMPORTANT:
/// This class does not know about Supabase,
/// Firebase, HTTP, or any other database technology.
abstract class HerbRepository {
  /// Get all herbs.
  Future<List<Herb>> getAllHerbs();

  /// Get the latest herbs.
  Future<List<Herb>> getLatestHerbs({
    int limit = 5,
  });

  /// Get trending herbs.
  Future<List<Herb>> getTrendingHerbs({
    int limit = 5,
  });

  /// Get the total number of herbs.
  Future<int> getHerbsCount();

  /// Get a single herb by its ID.
  Future<Herb?> getHerbById(String id);

  /// Search herbs by name.
  Future<List<Herb>> searchHerbs(String query);

  /// Get herbs associated with a specific condition.
  Future<List<Herb>> getHerbsByCondition(
    String conditionId,
  );

  /// Upload an image for a herb.
  Future<String> uploadHerbImage(
    String herbId,
    String fileName,
    Uint8List bytes,
  );

  /// Add an image record for a herb.
  Future<Herb> addHerbImage(
    HerbImage image,
  );

  /// Create a new herb.
  Future<Herb> createHerb(
    Herb herb,
  );

  /// Update an existing herb.
  Future<Herb> updateHerb(
    Herb herb,
  );

  /// Delete a herb.
  Future<void> deleteHerb(String id);
}