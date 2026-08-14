import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';


import '../models/herb_model.dart';

class HerbRemoteDataSource {
  final SupabaseClient client;

  HerbRemoteDataSource(this.client);

  // ============================================================
  // GET ALL HERBS
  // ============================================================

  /// Fetch all herbs together with their images and treatments.
  ///
  /// This is the layer that communicates directly with Supabase.
  Future<List<HerbModel>> getAllHerbs() async {
    final response = await client
        .from('herbs')
        .select('''
          *,
          herb_images(*),
          treatment_herbs(
            *,
            treatments(
              *,
              conditions(*)
            )
          )
        ''')
        .order('name_en');

    return (response as List<dynamic>)
        .map(
          (json) => HerbModel.fromJson(
            json as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  // ============================================================
  // GET LATEST HERBS
  // ============================================================

  /// Fetch the most recently created herbs.
  Future<List<HerbModel>> getLatestHerbs({
    int limit = 5,
  }) async {
    final response = await client
        .from('herbs')
        .select('''
          *,
          herb_images(*),
          treatment_herbs(
            *,
            treatments(
              *,
              conditions(*)
            )
          )
        ''')
        .order(
          'created_at',
          ascending: false,
        )
        .limit(limit);

    return (response as List<dynamic>)
        .map(
          (json) => HerbModel.fromJson(
            json as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  // ============================================================
  // GET TRENDING HERBS
  // ============================================================

  /// Get herbs based on recently updated records.
  ///
  /// For now, updated_at is being used as a simple
  /// approximation for "trending".
  Future<List<HerbModel>> getTrendingHerbs({
    int limit = 5,
  }) async {
    final response = await client
        .from('herbs')
        .select('''
          *,
          herb_images(*),
          treatment_herbs(
            *,
            treatments(
              *,
              conditions(*)
            )
          )
        ''')
        .order(
          'updated_at',
          ascending: false,
        )
        .limit(limit);

    return (response as List<dynamic>)
        .map(
          (json) => HerbModel.fromJson(
            json as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  // ============================================================
  // GET HERB COUNT
  // ============================================================

  /// Get the total number of herbs.
  Future<int> getHerbsCount() async {
    return await client
        .from('herbs')
        .count(CountOption.exact);
  }

  // ============================================================
  // GET SINGLE HERB
  // ============================================================

  /// Fetch one herb by its ID.
  Future<HerbModel?> getHerbById(
    String id,
  ) async {
    final response = await client
        .from('herbs')
        .select('''
          *,
          herb_images(*),
          treatment_herbs(
            *,
            treatments(
              *,
              conditions(*)
            )
          )
        ''')
        .eq('id', id)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return HerbModel.fromJson(response);
  }

  // ============================================================
  // SEARCH HERBS
  // ============================================================

  /// Search herbs using English, Shona or Ndebele names.
  Future<List<HerbModel>> searchHerbs(
    String query,
  ) async {
    final response = await client
        .from('herbs')
        .select('''
          *,
          herb_images(*),
          treatment_herbs(
            *,
            treatments(
              *,
              conditions(*)
            )
          )
        ''')
        .or(
          'name_en.ilike.%$query%,'
          'name_sn.ilike.%$query%,'
          'name_nd.ilike.%$query%',
        )
        .order('name_en');

    return (response as List<dynamic>)
        .map(
          (json) => HerbModel.fromJson(
            json as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  // ============================================================
  // GET HERBS BY CONDITION
  // ============================================================

  /// Find herbs associated with a specific condition.
  Future<List<HerbModel>> getHerbsByCondition(
    String conditionId,
  ) async {
    final response = await client
        .from('herbs')
        .select('''
          *,
          herb_images(*),
          treatment_herbs!inner(
            *,
            treatments(
              *,
              conditions(*)
            )
          )
        ''')
        .eq(
          'treatment_herbs.treatments.condition_id',
          conditionId,
        )
        .order('name_en');

    return (response as List<dynamic>)
        .map(
          (json) => HerbModel.fromJson(
            json as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  // ============================================================
  // ADD HERB IMAGE
  // ============================================================

  /// Add an image record to the herb_images table.
  Future<HerbModel> addHerbImage(
    HerbImageModel image,
  ) async {
    await client
        .from('herb_images')
        .insert(image.toJson());

    // Fetch the herb again so the returned model
    // contains the newly added image.
    return (await getHerbById(image.herbId))!;
  }

  // ============================================================
  // UPLOAD HERB IMAGE
  // ============================================================

  /// Upload an image to the Supabase Storage bucket.
  Future<String> uploadHerbImage(
    String herbId,
    String fileName,
    Uint8List bytes,
  ) async {
    final path = '$herbId/$fileName';

    await client.storage
        .from('herb-images')
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            upsert: true,
          ),
        );

    return client.storage
        .from('herb-images')
        .getPublicUrl(path);
  }

  // ============================================================
  // CREATE HERB
  // ============================================================

  /// Create a new herb.
  Future<HerbModel> createHerb(
    HerbModel herb,
  ) async {
    final response = await client
        .from('herbs')
        .insert(herb.toJson())
        .select()
        .single();

    return HerbModel.fromJson(response);
  }

  // ============================================================
  // UPDATE HERB
  // ============================================================

  /// Update an existing herb.
  Future<HerbModel> updateHerb(
    HerbModel herb,
  ) async {
    final response = await client
        .from('herbs')
        .update(herb.toJson())
        .eq('id', herb.id)
        .select()
        .single();

    return HerbModel.fromJson(response);
  }

  // ============================================================
  // DELETE HERB
  // ============================================================

  /// Delete an herb by its ID.
  Future<void> deleteHerb(
    String id,
  ) async {
    await client
        .from('herbs')
        .delete()
        .eq('id', id);
  }
}