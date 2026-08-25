import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/treatment_model.dart';

/// Communicates directly with the Supabase `treatments` table.
///
/// This is the DATA layer — it knows about Supabase.
/// All other layers receive data through this class.
class TreatmentRemoteDataSource {
  final SupabaseClient client;

  TreatmentRemoteDataSource(this.client);

  // ============================================================
  // GET ALL TREATMENTS
  // ============================================================

  /// Fetch all treatments with their conditions and herbs.
  Future<List<TreatmentModel>> getAllTreatments() async {
    final response = await client
        .from('treatments')
        .select('''
          *,
          conditions(*),
          treatment_herbs(*, herbs(*, herb_images(*)))
        ''')
        .order('name');

    return (response as List<dynamic>)
        .map((json) => TreatmentModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // GET SINGLE TREATMENT
  // ============================================================

  /// Fetch one treatment by its ID.
  Future<TreatmentModel?> getTreatmentById(String id) async {
    final response =
        await client
            .from('treatments')
            .select('''
          *,
          conditions(*),
          treatment_herbs(*, herbs(*, herb_images(*)))
        ''')
            .eq('id', id)
            .maybeSingle();

    if (response == null) return null;
    return TreatmentModel.fromJson(response);
  }

  // ============================================================
  // SEARCH TREATMENTS
  // ============================================================

  /// Search treatments by name or condition name.
  Future<List<TreatmentModel>> searchTreatments(String query) async {
    final response = await client
        .from('treatments')
        .select('''
          *,
          conditions!inner(*),
          treatment_herbs(*, herbs(*, herb_images(*)))
        ''')
        .or('name.ilike.%$query%,conditions.name.ilike.%$query%')
        .order('name');

    return (response as List<dynamic>)
        .map((json) => TreatmentModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // GET TREATMENTS BY CONDITION
  // ============================================================

  /// Get treatments for a specific condition.
  Future<List<TreatmentModel>> getTreatmentsByCondition(
    String conditionId,
  ) async {
    final response = await client
        .from('treatments')
        .select('''
          *,
          conditions!inner(*),
          treatment_herbs(*, herbs(*, herb_images(*)))
        ''')
        .eq('condition_id', conditionId)
        .order('name');

    return (response as List<dynamic>)
        .map((json) => TreatmentModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // GET TREATMENTS BY HERB
  // ============================================================

  /// Get treatments that use a specific herb.
  Future<List<TreatmentModel>> getTreatmentsByHerbId(String herbId) async {
    final response = await client
        .from('treatments')
        .select('''
          *,
          conditions(*),
          treatment_herbs!inner(*)
        ''')
        .eq('treatment_herbs.herb_id', herbId);

    return (response as List<dynamic>)
        .map((json) => TreatmentModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // GET TREATMENT COUNT
  // ============================================================

  /// Get the total number of treatments.
  Future<int> getTreatmentsCount() async {
    return await client.from('treatments').count(CountOption.exact);
  }

  // ============================================================
  // CREATE TREATMENT
  // ============================================================

  /// Create a new treatment and its associated herb entries.
  Future<TreatmentModel> createTreatment(
    TreatmentModel treatment,
    List<TreatmentHerbModel> herbs,
  ) async {
    // 1. Insert Treatment core data.
    final treatmentData = treatment.toJson();
    treatmentData.remove('id');
    treatmentData.remove('created_at');
    treatmentData.remove('updated_at');
    treatmentData.remove('treatment_herbs');
    treatmentData.remove('conditions');

    final treatmentResponse =
        await client
            .from('treatments')
            .insert(treatmentData)
            .select()
            .single();

    final newTreatmentId = treatmentResponse['id'] as String;

    // 2. Insert Treatment Herbs.
    List<Map<String, dynamic>> insertedHerbs = [];
    if (herbs.isNotEmpty) {
      final herbsData =
          herbs.map((h) {
            final Map<String, dynamic> data = h.toJson();
            data['treatment_id'] = newTreatmentId;
            data.remove('id');
            data.remove('created_at');
            data.remove('updated_at');
            data.remove('herbs');
            return data;
          }).toList();

      final herbsResponse =
          await client.from('treatment_herbs').insert(herbsData).select();
      insertedHerbs = List<Map<String, dynamic>>.from(herbsResponse);
    }

    // 3. Return partial model (caller may re-fetch for full data).
    return TreatmentModel.fromJson({
      ...treatmentResponse,
      'treatment_herbs': insertedHerbs,
    });
  }

  // ============================================================
  // UPDATE TREATMENT
  // ============================================================

  /// Update an existing treatment and refresh its herb associations.
  Future<TreatmentModel> updateTreatment(TreatmentModel treatment) async {
    // 1. Update core treatment data.
    final treatmentData = treatment.toJson();
    treatmentData.remove('id');
    treatmentData.remove('created_at');
    treatmentData.remove('updated_at');
    treatmentData.remove('treatment_herbs');
    treatmentData.remove('conditions');

    await client
        .from('treatments')
        .update(treatmentData)
        .eq('id', treatment.id);

    // 2. Refresh herb associations: delete old, insert new.
    await client
        .from('treatment_herbs')
        .delete()
        .eq('treatment_id', treatment.id);

    if (treatment.treatmentHerbs.isNotEmpty) {
      final herbsData =
          treatment.treatmentHerbs.map((h) {
            final Map<String, dynamic> data = h.toJson();
            data['treatment_id'] = treatment.id;
            data.remove('id');
            data.remove('created_at');
            data.remove('updated_at');
            data.remove('herbs');
            return data;
          }).toList();

      await client.from('treatment_herbs').insert(herbsData);
    }

    // 3. Re-fetch updated state.
    return (await getTreatmentById(treatment.id)) ?? treatment;
  }

  // ============================================================
  // DELETE TREATMENT
  // ============================================================

  /// Delete a treatment by its ID.
  Future<void> deleteTreatment(String id) async {
    await client.from('treatments').delete().eq('id', id);
  }

  // ============================================================
  // APPROVE TREATMENT
  // ============================================================

  /// Approve or disapprove a treatment.
  Future<void> approveTreatment(String id, {bool approved = true}) async {
    await client
        .from('treatments')
        .update({'is_approved': approved})
        .eq('id', id);
  }
}
