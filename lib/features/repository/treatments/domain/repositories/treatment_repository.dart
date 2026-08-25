import '../entities/treatment.dart';

/// Defines the operations that the application
/// can perform on treatments.
///
/// This is a DOMAIN contract.
///
/// IMPORTANT:
/// This class does not know about Supabase,
/// Firebase, HTTP, or any other database technology.
abstract class TreatmentRepository {
  /// Get all treatments with their conditions and herbs.
  Future<List<Treatment>> getAllTreatments();

  /// Get a single treatment by its ID.
  Future<Treatment?> getTreatmentById(String id);

  /// Search treatments by name or condition name.
  Future<List<Treatment>> searchTreatments(String query);

  /// Get treatments filtered by a specific condition.
  Future<List<Treatment>> getTreatmentsByCondition(String conditionId);

  /// Get treatments that use a specific herb.
  Future<List<Treatment>> getTreatmentsByHerbId(String herbId);

  /// Get the total number of treatments.
  Future<int> getTreatmentsCount();

  /// Create a new treatment with its associated herbs.
  Future<Treatment> createTreatment(Treatment treatment);

  /// Update an existing treatment (including its herbs).
  Future<Treatment> updateTreatment(Treatment treatment);

  /// Delete a treatment by its ID.
  Future<void> deleteTreatment(String id);

  /// Approve or disapprove a treatment.
  Future<void> approveTreatment(String id, {bool approved = true});
}
