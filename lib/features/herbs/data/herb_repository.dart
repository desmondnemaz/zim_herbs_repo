import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zim_herbs_repo/features/conditions/data/repository/model.dart';
import 'package:zim_herbs_repo/features/treatments/data/treatment_models.dart';
import 'models.dart';

class HerbRepository {
  final SupabaseClient _client;

  HerbRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  /// Fetch all herbs with their images and treatments
  Future<List<HerbModel>> getAllHerbs() async {
    final response = await _client
        .from('herbs')
        .select('''
          *,
          herb_images(*),
          treatment_herbs(*, treatments(*, conditions(*)))
        ''')
        .order('name_en');

    return (response as List<dynamic>)
        .map((json) => HerbModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get total count of herbs
  Future<int> getHerbsCount() async {
    return await _client.from('herbs').count(CountOption.exact);
  }

  /// Add an image record to the database
  Future<HerbModel> addHerbImage(HerbImageModel image) async {
    await _client.from('herb_images').insert(image.toJson());
    // Refetch the herb to get the updated list of images
    return (await getHerbById(image.herbId))!;
  }

  /// Fetch a single herb by ID with all related data
  Future<HerbModel?> getHerbById(String id) async {
    final response =
        await _client
            .from('herbs')
            .select('''
          *,
          herb_images(*),
          treatment_herbs(*, treatments(*, conditions(*)))
        ''')
            .eq('id', id)
            .maybeSingle();

    if (response == null) return null;
    return HerbModel.fromJson(response);
  }

  /// Search herbs by name (English, Shona, or Ndebele)
  Future<List<HerbModel>> searchHerbs(String query) async {
    final response = await _client
        .from('herbs')
        .select('''
          *,
          herb_images(*),
          treatment_herbs(*, treatments(*, conditions(*)))
        ''')
        .or(
          'name_en.ilike.%$query%,name_sn.ilike.%$query%,name_nd.ilike.%$query%',
        )
        .order('name_en');

    return (response as List<dynamic>)
        .map((json) => HerbModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetch all conditions
  Future<List<ConditionModel>> getAllConditions() async {
    final response = await _client.from('conditions').select().order('name');

    return (response as List<dynamic>)
        .map((json) => ConditionModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get herbs that treat a specific condition
  Future<List<HerbModel>> getHerbsByCondition(String conditionId) async {
    final response = await _client
        .from('herbs')
        .select('''
          *,
          herb_images(*),
          treatment_herbs!inner(*, treatments(*, conditions(*)))
        ''')
        .eq('treatment_herbs.treatments.condition_id', conditionId)
        .order('name_en');

    return (response as List<dynamic>)
        .map((json) => HerbModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Upload an image to herb-images bucket
  Future<String> uploadHerbImage(
    String herbId,
    String fileName,
    Uint8List bytes,
  ) async {
    final path = '$herbId/$fileName';
    await _client.storage
        .from('herb-images')
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    return _client.storage.from('herb-images').getPublicUrl(path);
  }

  /// Create a new herb
  Future<HerbModel> createHerb(HerbModel herb) async {
    final response =
        await _client.from('herbs').insert(herb.toJson()).select().single();
    return HerbModel.fromJson(response);
  }

  /// Update an existing herb
  Future<HerbModel> updateHerb(HerbModel herb) async {
    final response =
        await _client
            .from('herbs')
            .update(herb.toJson())
            .eq('id', herb.id)
            .select()
            .single();
    return HerbModel.fromJson(response);
  }

  /// Delete a herb
  Future<void> deleteHerb(String id) async {
    await _client.from('herbs').delete().eq('id', id);
  }

  /// Create a new condition
  Future<ConditionModel> createCondition(ConditionModel condition) async {
    final response =
        await _client
            .from('conditions')
            .insert(condition.toJson())
            .select()
            .single();
    return ConditionModel.fromJson(response);
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
            return data;
          }).toList();

      final herbsResponse =
          await _client.from('treatment_herbs').insert(herbsData).select();
      insertedHerbs = List<Map<String, dynamic>>.from(herbsResponse);
    }

    // 3. Construct and return full object
    return TreatmentModel.fromJson({
      ...treatmentResponse,
      'treatment_herbs': insertedHerbs,
    });
  }
}
