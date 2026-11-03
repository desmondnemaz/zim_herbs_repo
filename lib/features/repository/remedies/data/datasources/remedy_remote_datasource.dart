import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zim_herbs_repo/core/utils/enums.dart';
import '../models/remedy_model.dart';

/// Communicates directly with the Supabase `remedies` table.
///
/// This is the DATA layer — it knows about Supabase.
/// All other layers receive data through this class.
class RemedyRemoteDataSource {
  final SupabaseClient client;

  RemedyRemoteDataSource(this.client);

  bool? _useAilmentsRelation;

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

  // ============================================================
  // GET ALL REMEDIES
  // ============================================================

  /// Fetch all remedies with their conditions/ailments and herbs.
  Future<List<RemedyModel>> getAllRemedies() async {
    final useAilments = await _checkAilmentsRelation();
    final relation = useAilments ? 'ailments(*)' : 'conditions(*)';
    final response = await client
        .from('remedies')
        .select('''
          *,
          $relation,
          remedy_herbs(*, herbs(*, herb_images(*)))
        ''')
        .order('name');

    return (response as List<dynamic>)
        .map((json) => RemedyModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // GET SINGLE REMEDY
  // ============================================================

  /// Fetch one remedy by its ID.
  Future<RemedyModel?> getRemedyById(String id) async {
    final useAilments = await _checkAilmentsRelation();
    final relation = useAilments ? 'ailments(*)' : 'conditions(*)';
    final response =
        await client
            .from('remedies')
            .select('''
          *,
          $relation,
          remedy_herbs(*, herbs(*, herb_images(*)))
        ''')
            .eq('id', id)
            .maybeSingle();

    if (response == null) return null;
    return RemedyModel.fromJson(response);
  }

  // ============================================================
  // SEARCH REMEDIES
  // ============================================================

  /// Search remedies by name or condition/ailment name.
  Future<List<RemedyModel>> searchRemedies(String query) async {
    final useAilments = await _checkAilmentsRelation();
    final table = useAilments ? 'ailments' : 'conditions';
    final response = await client
        .from('remedies')
        .select('''
          *,
          $table!inner(*),
          remedy_herbs(*, herbs(*, herb_images(*)))
        ''')
        .or('name.ilike.%$query%,$table.name.ilike.%$query%')
        .order('name');

    return (response as List<dynamic>)
        .map((json) => RemedyModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // GET REMEDIES BY CONDITION / AILMENT
  // ============================================================

  /// Get remedies for a specific condition or ailment.
  Future<List<RemedyModel>> getRemediesByCondition(
    String conditionId,
  ) async {
    final useAilments = await _checkAilmentsRelation();
    final table = useAilments ? 'ailments' : 'conditions';
    final col = useAilments ? 'ailment_id' : 'condition_id';
    final response = await client
        .from('remedies')
        .select('''
          *,
          $table!inner(*),
          remedy_herbs(*, herbs(*, herb_images(*)))
        ''')
        .eq(col, conditionId)
        .order('name');

    return (response as List<dynamic>)
        .map((json) => RemedyModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Alias for ailment
  Future<List<RemedyModel>> getRemediesByAilment(String ailmentId) =>
      getRemediesByCondition(ailmentId);

  // ============================================================
  // GET REMEDIES BY HERB
  // ============================================================

  /// Get remedies that use a specific herb.
  Future<List<RemedyModel>> getRemediesByHerbId(String herbId) async {
    final useAilments = await _checkAilmentsRelation();
    final relation = useAilments ? 'ailments(*)' : 'conditions(*)';
    final response = await client
        .from('remedies')
        .select('''
          *,
          $relation,
          remedy_herbs!inner(*)
        ''')
        .eq('remedy_herbs.herb_id', herbId);

    return (response as List<dynamic>)
        .map((json) => RemedyModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // GET REMEDY COUNT
  // ============================================================

  /// Get the total number of remedies.
  Future<int> getRemediesCount() async {
    return await client.from('remedies').count(CountOption.exact);
  }

  // ============================================================
  // CREATE REMEDY
  // ============================================================

  /// Create a new remedy and its associated herb entries.
  Future<RemedyModel> createRemedy(
    RemedyModel remedy,
    List<RemedyHerbModel> herbs,
  ) async {
    // 1. Insert Remedy core data.
    final remedyData = remedy.toJson();
    remedyData.remove('id');
    remedyData.remove('created_at');
    remedyData.remove('updated_at');
    remedyData.remove('remedy_herbs');
    remedyData.remove('treatment_herbs');
    remedyData.remove('conditions');
    remedyData.remove('ailments');

    final useAilments = await _checkAilmentsRelation();
    if (useAilments) {
      remedyData['ailment_id'] = remedy.conditionId;
      remedyData.remove('condition_id');
    }

    final remedyResponse =
        await client
            .from('remedies')
            .insert(remedyData)
            .select()
            .single();

    final newRemedyId = remedyResponse['id'] as String;

    // 2. Insert Remedy Herbs.
    List<Map<String, dynamic>> insertedHerbs = [];
    if (herbs.isNotEmpty) {
      final herbsData =
          herbs.map((h) {
            final Map<String, dynamic> data = h.toJson();
            data['remedy_id'] = newRemedyId;
            data.remove('id');
            data.remove('created_at');
            data.remove('updated_at');
            data.remove('herbs');
            return data;
          }).toList();

      final herbsResponse =
          await client.from('remedy_herbs').insert(herbsData).select();
      insertedHerbs = List<Map<String, dynamic>>.from(herbsResponse);
    }

    // 3. Return partial model (caller may re-fetch for full data).
    return RemedyModel.fromJson({
      ...remedyResponse,
      'remedy_herbs': insertedHerbs,
    });
  }

  // ============================================================
  // UPDATE REMEDY
  // ============================================================

  /// Update an existing remedy and refresh its herb associations.
  Future<RemedyModel> updateRemedy(RemedyModel remedy) async {
    // 1. Update core remedy data.
    final remedyData = remedy.toJson();
    remedyData.remove('id');
    remedyData.remove('created_at');
    remedyData.remove('updated_at');
    remedyData.remove('remedy_herbs');
    remedyData.remove('treatment_herbs');
    remedyData.remove('conditions');
    remedyData.remove('ailments');

    final useAilments = await _checkAilmentsRelation();
    if (useAilments) {
      remedyData['ailment_id'] = remedy.conditionId;
      remedyData.remove('condition_id');
    }

    await client
        .from('remedies')
        .update(remedyData)
        .eq('id', remedy.id);

    // 2. Refresh herb associations: delete old, insert new.
    await client
        .from('remedy_herbs')
        .delete()
        .eq('remedy_id', remedy.id);

    if (remedy.remedyHerbs.isNotEmpty) {
      final herbsData =
          remedy.remedyHerbs.map((h) {
            final Map<String, dynamic> data = h.toJson();
            data['remedy_id'] = remedy.id;
            data.remove('id');
            data.remove('created_at');
            data.remove('updated_at');
            data.remove('herbs');
            return data;
          }).toList();

      await client.from('remedy_herbs').insert(herbsData);
    }

    // 3. Re-fetch updated state.
    return (await getRemedyById(remedy.id)) ?? remedy;
  }

  // ============================================================
  // DELETE REMEDY
  // ============================================================

  /// Delete a remedy by its ID.
  /// Delete a remedy by its ID.
  Future<void> deleteRemedy(String id) async {
    await client.from('remedies').delete().eq('id', id);
  }

  /// Delete multiple remedies by their IDs.
  Future<void> deleteRemediesBatch(List<String> ids) async {
    if (ids.isEmpty) return;
    await client.from('remedies').delete().inFilter('id', ids);
  }

  // ============================================================
  // APPROVE / VERIFY REMEDY
  // ============================================================

  /// Approve or disapprove a remedy with full audit traceability.
  Future<void> approveRemedy(
    String id, {
    bool approved = true,
    String? verifiedBy,
    String? moderationNotes,
  }) async {
    final now = DateTime.now().toIso8601String();
    final updateData = <String, dynamic>{
      'is_approved': approved,
      'validation_status': approved
          ? RecordValidationStatus.published.dbValue
          : RecordValidationStatus.submitted.dbValue,
      'updated_at': now,
    };

    if (verifiedBy != null) {
      if (approved) {
        updateData['approved_by'] = verifiedBy;
        updateData['approved_at'] = now;
        updateData['published_by'] = verifiedBy;
        updateData['published_at'] = now;
        updateData['rejected_by'] = null;
        updateData['rejected_at'] = null;
      } else {
        updateData['approved_by'] = null;
        updateData['approved_at'] = null;
      }
    }

    if (moderationNotes != null) {
      updateData['moderation_comments'] = moderationNotes;
      updateData['rejection_reason'] = moderationNotes;
    }

    await client.from('remedies').update(updateData).eq('id', id);
  }

  /// Updates remedy verification status with audit attribution and feedback notes.
  Future<void> updateRemedyVerification(
    String remedyId,
    bool isApproved, {
    String? verifiedBy,
    String? moderationNotes,
  }) async {
    await approveRemedy(
      remedyId,
      approved: isApproved,
      verifiedBy: verifiedBy,
      moderationNotes: moderationNotes,
    );
  }
}
