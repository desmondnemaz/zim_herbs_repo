import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
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
          treatments(*, conditions(*))
        ''')
        .order('name_en');

    return (response as List<dynamic>)
        .map((json) => HerbModel.fromJson(json as Map<String, dynamic>))
        .toList();
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
          treatments(*, conditions(*))
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
          treatments(*, conditions(*))
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
          treatments!inner(*, conditions(*))
        ''')
        .eq('treatments.condition_id', conditionId)
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
}
