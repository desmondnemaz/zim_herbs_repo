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
}
