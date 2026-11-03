import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zim_herbs_repo/core/utils/enums.dart';

import '../models/herb_model.dart';

class HerbRemoteDataSource {
  final SupabaseClient client;

  HerbRemoteDataSource(this.client);

  bool? _useAilmentsRelation;
  bool? _useOtherUsesRelation;

  Future<bool> _checkAilmentsRelation() async {
    if (_useAilmentsRelation != null) return _useAilmentsRelation!;
    try {
      await client.from('ailments').select('id').limit(1);
      _useAilmentsRelation = true;
    } catch (_) {
      _useAilmentsRelation = false;
    }
    return _useAilmentsRelation!;
  }

  Future<bool> _checkOtherUsesRelation() async {
    if (_useOtherUsesRelation != null) return _useOtherUsesRelation!;
    try {
      await client.from('herb_other_uses').select('id').limit(1);
      _useOtherUsesRelation = true;
    } catch (_) {
      _useOtherUsesRelation = false;
    }
    return _useOtherUsesRelation!;
  }

  Future<String> _getHerbSelectQuery({bool innerRemedies = false}) async {
    final useAilments = await _checkAilmentsRelation();
    final useOtherUses = await _checkOtherUsesRelation();
    final relation = useAilments ? 'ailments(*)' : 'conditions(*)';
    final otherUsesRelation = useOtherUses ? ', herb_other_uses(*)' : '';
    final remedyRelation =
        innerRemedies ? 'remedy_herbs!inner(' : 'remedy_herbs(';
    return '''
      *,
      herb_images(*)$otherUsesRelation,
      $remedyRelation
        *,
        remedies(
          *,
          $relation
        )
      )
    ''';
  }

  // ============================================================
  // GET ALL HERBS
  // ============================================================

  /// Fetch all herbs together with their images and treatments.
  ///
  /// This is the layer that communicates directly with Supabase.
  Future<List<HerbModel>> getAllHerbs() async {
    final query = await _getHerbSelectQuery();
    final response = await client
        .from('herbs')
        .select(query)
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
  // GET UNVERIFIED HERBS
  // ============================================================

  /// Fetch herbs that are unverified / pending moderator review.
  Future<List<HerbModel>> getUnverifiedHerbs() async {
    final query = await _getHerbSelectQuery();
    final response = await client
        .from('herbs')
        .select(query)
        .or('is_approved.is.false,is_approved.is.null')
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map(
          (json) => HerbModel.fromJson(
            json as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  /// Update herb verification status using the validation lifecycle.
  Future<void> updateHerbVerification(
    String herbId,
    bool isApproved, {
    String? verifiedBy,
    String? moderationNotes,
    RecordValidationStatus? status,
  }) async {
    final now = DateTime.now().toIso8601String();
    final effectiveStatus = status ??
        (isApproved
            ? RecordValidationStatus.published
            : RecordValidationStatus.underReview);

    final updateData = <String, dynamic>{
      'is_approved': effectiveStatus == RecordValidationStatus.published,
      'validation_status': effectiveStatus.dbValue,
      'updated_at': now,
    };

    if (effectiveStatus == RecordValidationStatus.published) {
      updateData['verified_by'] = verifiedBy;
      updateData['verified_at'] = now;
      updateData['published_by'] = verifiedBy;
      updateData['published_at'] = now;
    } else if (effectiveStatus == RecordValidationStatus.validated) {
      updateData['verified_by'] = verifiedBy;
      updateData['verified_at'] = now;
    } else if (effectiveStatus == RecordValidationStatus.rejected) {
      updateData['rejected_by'] = verifiedBy;
      updateData['rejected_at'] = now;
      if (moderationNotes != null) {
        updateData['rejection_reason'] = moderationNotes;
      }
    }

    if (moderationNotes != null) {
      updateData['moderation_notes'] = moderationNotes;
    }

    await client.from('herbs').update(updateData).eq('id', herbId);
  }

  /// Unpublish an active herb (takes off public shelf, moves to validated, under_review, or archived).
  Future<void> unpublishHerb(
    String herbId, {
    RecordValidationStatus targetStatus = RecordValidationStatus.validated,
    String? moderatorId,
    String? reason,
  }) async {
    final now = DateTime.now().toIso8601String();
    final updateData = <String, dynamic>{
      'is_approved': false,
      'validation_status': targetStatus.dbValue,
      'updated_at': now,
      'unpublished_at': now,
    };

    if (moderatorId != null) {
      updateData['unpublished_by'] = moderatorId;
      updateData['updated_by'] = moderatorId;
    }
    if (reason != null && reason.trim().isNotEmpty) {
      updateData['unpublish_reason'] = reason.trim();
      updateData['moderation_notes'] = reason.trim();
    }

    await client.from('herbs').update(updateData).eq('id', herbId);
  }

  // ============================================================
  // GET LATEST HERBS
  // ============================================================

  /// Fetch the most recently created herbs.
  Future<List<HerbModel>> getLatestHerbs({
    int limit = 5,
  }) async {
    final query = await _getHerbSelectQuery();
    final response = await client
        .from('herbs')
        .select(query)
        .eq('is_approved', true)
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
    final query = await _getHerbSelectQuery();
    final response = await client
        .from('herbs')
        .select(query)
        .eq('is_approved', true)
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
    final query = await _getHerbSelectQuery();
    final response = await client
        .from('herbs')
        .select(query)
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
    final selectQuery = await _getHerbSelectQuery();
    final response = await client
        .from('herbs')
        .select(selectQuery)
        .or(
          'name_en.ilike.%$query%,'
          'name_sn.ilike.%$query%,'
          'name_nd.ilike.%$query%,'
          'scientific_name.ilike.%$query%,'
          'places_found.ilike.%$query%',
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
  // GET HERBS BY CONDITION / AILMENT
  // ============================================================

  /// Find herbs associated with a specific condition or ailment.
  Future<List<HerbModel>> getHerbsByCondition(
    String conditionId,
  ) async {
    final selectQuery = await _getHerbSelectQuery(innerRemedies: true);
    final useAilments = await _checkAilmentsRelation();
    final conditionCol = useAilments
        ? 'remedy_herbs.remedies.ailment_id'
        : 'remedy_herbs.remedies.condition_id';

    final response = await client
        .from('herbs')
        .select(selectQuery)
        .eq(
          conditionCol,
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

  /// Alias for ailment
  Future<List<HerbModel>> getHerbsByAilment(String ailmentId) =>
      getHerbsByCondition(ailmentId);

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

  /// Delete multiple herbs by their IDs.
  Future<void> deleteHerbs(
    List<String> ids,
  ) async {
    if (ids.isEmpty) return;
    await client
        .from('herbs')
        .delete()
        .inFilter('id', ids);
  }

  // ============================================================
  // HERB OTHER USES
  // ============================================================

  /// Add a non-medicinal use to herb_other_uses table.
  Future<void> addHerbOtherUse(Map<String, dynamic> useJson) async {
    await client.from('herb_other_uses').insert(useJson);
  }

  /// Delete a non-medicinal use by its ID.
  Future<void> deleteHerbOtherUse(String useId) async {
    await client.from('herb_other_uses').delete().eq('id', useId);
  }
}