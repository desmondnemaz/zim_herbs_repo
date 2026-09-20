import '../entities/remedy.dart';

/// Defines the operations that the application
/// can perform on remedies.
///
/// This is a DOMAIN contract.
///
/// IMPORTANT:
/// This class does not know about Supabase,
/// Firebase, HTTP, or any other database technology.
abstract class RemedyRepository {
  /// Get all remedies with their conditions and herbs.
  Future<List<Remedy>> getAllRemedies();

  /// Get a single remedy by its ID.
  Future<Remedy?> getRemedyById(String id);

  /// Search remedies by name or condition name.
  Future<List<Remedy>> searchRemedies(String query);

  /// Get remedies filtered by a specific condition.
  Future<List<Remedy>> getRemediesByCondition(String conditionId);

  /// Get remedies that use a specific herb.
  Future<List<Remedy>> getRemediesByHerbId(String herbId);

  /// Get the total number of remedies.
  Future<int> getRemediesCount();

  /// Create a new remedy with its associated herbs.
  Future<Remedy> createRemedy(Remedy remedy);

  /// Update an existing remedy (including its herbs).
  Future<Remedy> updateRemedy(Remedy remedy);

  /// Delete a remedy by its ID.
  Future<void> deleteRemedy(String id);

  /// Approve or disapprove a remedy.
  Future<void> approveRemedy(String id, {bool approved = true});
}
