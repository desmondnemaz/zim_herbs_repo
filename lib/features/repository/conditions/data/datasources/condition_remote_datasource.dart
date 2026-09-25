import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zim_herbs_repo/core/utils/enums.dart';
import '../models/body_part_model.dart';
import '../models/condition_model.dart';

class ConditionRemoteDataSource {
  final SupabaseClient client;

  ConditionRemoteDataSource(this.client);

  static const String _conditionSelect = '''
    *,
    condition_body_parts (
      condition_id,
      body_part_id,
      body_parts (*)
    )
  ''';

  // ============================================================
  // CONDITIONS
  // ============================================================

  /// Fetch all conditions ordered by name with associated body parts.
  Future<List<ConditionModel>> getAllConditions() async {
    final response = await client
        .from('conditions')
        .select(_conditionSelect)
        .order('name');

    return (response as List<dynamic>)
        .map((json) => ConditionModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get total count of conditions.
  Future<int> getConditionsCount() async {
    return await client.from('conditions').count(CountOption.exact);
  }

  /// Fetch a condition by ID with associated body parts.
  Future<ConditionModel?> getConditionById(String id) async {
    final response = await client
        .from('conditions')
        .select(_conditionSelect)
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return ConditionModel.fromJson(response);
  }

  /// Fetch conditions filtered by body system.
  Future<List<ConditionModel>> getConditionsByBodySystem(
    BodySystem bodySystem,
  ) async {
    final response = await client
        .from('conditions')
        .select(_conditionSelect)
        .eq('body_system', bodySystemToString(bodySystem))
        .order('name');

    return (response as List<dynamic>)
        .map((json) => ConditionModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Search conditions by name.
  Future<List<ConditionModel>> searchConditions(String query) async {
    final response = await client
        .from('conditions')
        .select(_conditionSelect)
        .ilike('name', '%$query%')
        .order('name');

    return (response as List<dynamic>)
        .map((json) => ConditionModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetch conditions that affect a specific body part.
  Future<List<ConditionModel>> getConditionsByBodyPart(
    String bodyPartId,
  ) async {
    // 1. Query condition IDs from condition_body_parts
    final junctionRows = await client
        .from('condition_body_parts')
        .select('condition_id')
        .eq('body_part_id', bodyPartId);

    final conditionIds = (junctionRows as List<dynamic>)
        .map((row) => row['condition_id'] as String)
        .toSet()
        .toList();

    if (conditionIds.isEmpty) return [];

    // 2. Fetch those conditions
    final response = await client
        .from('conditions')
        .select(_conditionSelect)
        .inFilter('id', conditionIds)
        .order('name');

    return (response as List<dynamic>)
        .map((json) => ConditionModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Create a new condition and link body parts if provided.
  Future<ConditionModel> createCondition(
    ConditionModel condition, {
    List<String>? bodyPartIds,
  }) async {
    final response = await client
        .from('conditions')
        .insert(condition.toJson())
        .select()
        .single();

    final createdId = response['id'] as String;

    final targetBodyPartIds =
        bodyPartIds ?? condition.bodyParts.map((bp) => bp.id).toList();

    if (targetBodyPartIds.isNotEmpty) {
      await _syncConditionBodyParts(createdId, targetBodyPartIds);
    }

    final fullCondition = await getConditionById(createdId);
    return fullCondition ?? ConditionModel.fromJson(response);
  }

  /// Update an existing condition and update body part associations.
  Future<ConditionModel> updateCondition(
    ConditionModel condition, {
    List<String>? bodyPartIds,
  }) async {
    final response = await client
        .from('conditions')
        .update(condition.toJson())
        .eq('id', condition.id)
        .select()
        .single();

    final targetBodyPartIds =
        bodyPartIds ?? condition.bodyParts.map((bp) => bp.id).toList();

    await _syncConditionBodyParts(condition.id, targetBodyPartIds);

    final fullCondition = await getConditionById(condition.id);
    return fullCondition ?? ConditionModel.fromJson(response);
  }

  /// Delete a condition and its relations.
  Future<void> deleteCondition(String id) async {
    await client.from('condition_body_parts').delete().eq('condition_id', id);
    await client.from('conditions').delete().eq('id', id);
  }

  // ============================================================
  // BODY PARTS
  // ============================================================

  /// Fetch all available body parts ordered by English name.
  Future<List<BodyPartModel>> getAllBodyParts() async {
    final response = await client
        .from('body_parts')
        .select()
        .order('name_en');

    return (response as List<dynamic>)
        .map((json) => BodyPartModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetch a single body part by ID.
  Future<BodyPartModel?> getBodyPartById(String id) async {
    final response =
        await client.from('body_parts').select().eq('id', id).maybeSingle();

    if (response == null) return null;
    return BodyPartModel.fromJson(response);
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  /// Synchronize condition_body_parts junction table.
  Future<void> _syncConditionBodyParts(
    String conditionId,
    List<String> bodyPartIds,
  ) async {
    // 1. Remove existing condition_body_parts rows for this condition
    await client
        .from('condition_body_parts')
        .delete()
        .eq('condition_id', conditionId);

    // 2. Insert new relations
    final uniqueIds = bodyPartIds.toSet().toList();
    if (uniqueIds.isNotEmpty) {
      final rowsToInsert = uniqueIds.map((bpId) {
        return {
          'condition_id': conditionId,
          'body_part_id': bpId,
        };
      }).toList();

      await client.from('condition_body_parts').insert(rowsToInsert);
    }
  }
}
