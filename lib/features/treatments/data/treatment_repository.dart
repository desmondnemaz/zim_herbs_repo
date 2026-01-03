import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zim_herbs_repo/features/treatments/data/treatment_models.dart';

class TreatmentRepository {
  final SupabaseClient _client;

  TreatmentRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  /// Fetch all treatments with their conditions and herbs
  Future<List<TreatmentModel>> getAllTreatments() async {
    final response = await _client
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

  /// Fetch a single treatment by ID with its conditions and herbs
  Future<TreatmentModel?> getTreatmentById(String id) async {
    final response =
        await _client
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

  /// Search treatments by name or condition
  Future<List<TreatmentModel>> searchTreatments(String query) async {
    final response = await _client
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

  /// Get treatments filtered by a specific condition
  Future<List<TreatmentModel>> getTreatmentsByCondition(
    String conditionId,
  ) async {
    final response = await _client
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

  /// Get treatments that use a specific herb
  Future<List<TreatmentModel>> getTreatmentsByHerbId(String herbId) async {
    // We want treatments where ANY of the treatment_herbs match the herbId.
    // Using !inner on treatment_herbs forces an inner join, filtering out treatments with no matching herbs.
    final response = await _client
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

  /// Create a new treatment with herbs
  Future<TreatmentModel> createTreatment(
    TreatmentModel treatment,
    List<TreatmentHerbModel> herbs,
  ) async {
    // 1. Insert Treatment
    final treatmentData = treatment.toJson();
    treatmentData.remove('id');
    treatmentData.remove('created_at');
    treatmentData.remove('updated_at');

    // Remove complex nested objects before insert
    treatmentData.remove('treatment_herbs');
    treatmentData.remove('conditions');

    final treatmentResponse =
        await _client
            .from('treatments')
            .insert(treatmentData)
            .select()
            .single();

    final newTreatmentId = treatmentResponse['id'] as String;

    // 2. Insert Treatment Herbs
    List<Map<String, dynamic>> insertedHerbs = [];
    if (herbs.isNotEmpty) {
      final herbsData =
          herbs.map((h) {
            final Map<String, dynamic> data = h.toJson();
            data['treatment_id'] = newTreatmentId;
            data.remove('id');
            data.remove('created_at');
            data.remove('updated_at');
            data.remove('herbs'); // Remove nested herb model
            return data;
          }).toList();

      final herbsResponse =
          await _client.from('treatment_herbs').insert(herbsData).select();
      insertedHerbs = List<Map<String, dynamic>>.from(herbsResponse);
    }

    // 3. Construct and return full object (partial, usually we'd re-fetch)
    return TreatmentModel.fromJson({
      ...treatmentResponse,
      'treatment_herbs': insertedHerbs,
    });
  }

  /// Get total count of treatments
  Future<int> getTreatmentsCount() async {
    return await _client.from('treatments').count(CountOption.exact);
  }

  /// Update an existing treatment
  Future<TreatmentModel> updateTreatment(TreatmentModel treatment) async {
    // 1. Update Treatment core data
    final treatmentData = treatment.toJson();
    treatmentData.remove('id');
    treatmentData.remove('created_at');
    treatmentData.remove('updated_at');
    treatmentData.remove('treatment_herbs');
    treatmentData.remove('conditions');

    await _client
        .from('treatments')
        .update(treatmentData)
        .eq('id', treatment.id);

    // 2. Refresh Treatment Herbs: Delete old and insert new
    await _client
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

      await _client.from('treatment_herbs').insert(herbsData);
    }

    // 3. Re-fetch current state to ensure full object is returned
    return await getTreatmentById(treatment.id) ?? treatment;
  }

  /// Delete a treatment
  Future<void> deleteTreatment(String id) async {
    await _client.from('treatments').delete().eq('id', id);
  }

  /// Approve or disapprove a treatment
  Future<void> approveTreatment(String id, {bool approved = true}) async {
    await _client
        .from('treatments')
        .update({'is_approved': approved})
        .eq('id', id);
  }
}
