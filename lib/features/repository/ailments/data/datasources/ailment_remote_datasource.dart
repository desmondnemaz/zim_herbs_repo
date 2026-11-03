import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zim_herbs_repo/core/utils/enums.dart';
import '../models/ailment_model.dart';
import '../models/body_part_model.dart';

class AilmentRemoteDataSource {
  final SupabaseClient client;

  AilmentRemoteDataSource(this.client);

  static const String _ailmentSelect = '''
    *,
    ailment_body_parts (
      ailment_id,
      body_part_id,
      body_parts (*)
    )
  ''';

  static const String _legacyConditionSelect = '''
    *,
    condition_body_parts (
      condition_id,
      body_part_id,
      body_parts (*)
    )
  ''';

  String _tableName = 'ailments';
  String _junctionTable = 'ailment_body_parts';
  String _junctionFk = 'ailment_id';
  String _activeSelect = _ailmentSelect;
  bool _schemaChecked = false;

  Future<void> _ensureSchema() async {
    if (_schemaChecked) return;
    try {
      await client.from('ailments').select('id').limit(1);
      _tableName = 'ailments';
      _junctionTable = 'ailment_body_parts';
      _junctionFk = 'ailment_id';
      _activeSelect = _ailmentSelect;
    } catch (_) {
      // Fallback to legacy tables if migration has not run yet
      _tableName = 'conditions';
      _junctionTable = 'condition_body_parts';
      _junctionFk = 'condition_id';
      _activeSelect = _legacyConditionSelect;
    }
    _schemaChecked = true;
  }

  // ============================================================
  // AILMENTS
  // ============================================================

  /// Fetch all ailments ordered by name with associated body parts.
  Future<List<AilmentModel>> getAllAilments() async {
    await _ensureSchema();
    final response = await client
        .from(_tableName)
        .select(_activeSelect)
        .order('name');

    return (response as List<dynamic>)
        .map((json) => AilmentModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get total count of ailments.
  Future<int> getAilmentsCount() async {
    await _ensureSchema();
    return await client.from(_tableName).count(CountOption.exact);
  }

  /// Fetch an ailment by ID with associated body parts.
  Future<AilmentModel?> getAilmentById(String id) async {
    await _ensureSchema();
    final response = await client
        .from(_tableName)
        .select(_activeSelect)
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return AilmentModel.fromJson(response);
  }

  /// Fetch ailments filtered by category.
  Future<List<AilmentModel>> getAilmentsByCategory(
    AilmentCategory category,
  ) async {
    await _ensureSchema();
    final categoryStr = ailmentCategoryToString(category);

    try {
      final response = await client
          .from(_tableName)
          .select(_activeSelect)
          .eq('ailment_category', categoryStr)
          .order('name');

      return (response as List<dynamic>)
          .map((json) => AilmentModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      final response = await client
          .from(_tableName)
          .select(_activeSelect)
          .eq('body_system', categoryStr)
          .order('name');

      return (response as List<dynamic>)
          .map((json) => AilmentModel.fromJson(json as Map<String, dynamic>))
          .toList();
    }
  }

  /// Search ailments by name.
  Future<List<AilmentModel>> searchAilments(String query) async {
    await _ensureSchema();
    final response = await client
        .from(_tableName)
        .select(_activeSelect)
        .ilike('name', '%$query%')
        .order('name');

    return (response as List<dynamic>)
        .map((json) => AilmentModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetch ailments that affect a specific body part.
  Future<List<AilmentModel>> getAilmentsByBodyPart(String bodyPartId) async {
    await _ensureSchema();
    final junctionRows = await client
        .from(_junctionTable)
        .select(_junctionFk)
        .eq('body_part_id', bodyPartId);

    final ailmentIds = (junctionRows as List<dynamic>)
        .map((row) => row[_junctionFk] as String)
        .toSet()
        .toList();

    if (ailmentIds.isEmpty) return [];

    final response = await client
        .from(_tableName)
        .select(_activeSelect)
        .inFilter('id', ailmentIds)
        .order('name');

    return (response as List<dynamic>)
        .map((json) => AilmentModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Create a new ailment and link body parts if provided.
  Future<AilmentModel> createAilment(
    AilmentModel ailment, {
    List<String>? bodyPartIds,
  }) async {
    await _ensureSchema();
    final payload = ailment.toJson();
    if (_tableName == 'conditions') {
      payload['body_system'] = payload['ailment_category'];
    }

    final response = await client
        .from(_tableName)
        .insert(payload)
        .select()
        .single();

    final createdId = response['id'] as String;
    final targetBodyPartIds =
        bodyPartIds ?? ailment.bodyParts.map((bp) => bp.id).toList();

    if (targetBodyPartIds.isNotEmpty) {
      await _syncAilmentBodyParts(createdId, targetBodyPartIds);
    }

    final full = await getAilmentById(createdId);
    return full ?? AilmentModel.fromJson(response);
  }

  /// Update an existing ailment and update body part associations.
  Future<AilmentModel> updateAilment(
    AilmentModel ailment, {
    List<String>? bodyPartIds,
  }) async {
    await _ensureSchema();
    final payload = ailment.toJson();
    if (_tableName == 'conditions') {
      payload['body_system'] = payload['ailment_category'];
    }

    final response = await client
        .from(_tableName)
        .update(payload)
        .eq('id', ailment.id)
        .select()
        .single();

    final targetBodyPartIds =
        bodyPartIds ?? ailment.bodyParts.map((bp) => bp.id).toList();

    await _syncAilmentBodyParts(ailment.id, targetBodyPartIds);

    final full = await getAilmentById(ailment.id);
    return full ?? AilmentModel.fromJson(response);
  }

  /// Delete an ailment and its relations.
  Future<void> deleteAilment(String id) async {
    await _ensureSchema();
    await client.from(_junctionTable).delete().eq(_junctionFk, id);
    await client.from(_tableName).delete().eq('id', id);
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

  /// Create a new body part.
  Future<BodyPartModel> createBodyPart(BodyPartModel bodyPart) async {
    final data = bodyPart.toJson(forInsert: true);
    final response = await client
        .from('body_parts')
        .insert(data)
        .select()
        .single();

    return BodyPartModel.fromJson(response);
  }

  /// Update an existing body part.
  Future<BodyPartModel> updateBodyPart(BodyPartModel bodyPart) async {
    final data = bodyPart.toJson();
    final response = await client
        .from('body_parts')
        .update(data)
        .eq('id', bodyPart.id)
        .select()
        .single();

    return BodyPartModel.fromJson(response);
  }

  /// Delete a body part and its links in junction table.
  Future<void> deleteBodyPart(String id) async {
    await _ensureSchema();
    await client.from(_junctionTable).delete().eq('body_part_id', id);
    await client.from('body_parts').delete().eq('id', id);
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  /// Synchronize junction table.
  Future<void> _syncAilmentBodyParts(
    String ailmentId,
    List<String> bodyPartIds,
  ) async {
    await _ensureSchema();
    await client.from(_junctionTable).delete().eq(_junctionFk, ailmentId);

    final uniqueIds = bodyPartIds.toSet().toList();
    if (uniqueIds.isNotEmpty) {
      final rowsToInsert = uniqueIds.map((bpId) {
        return {
          _junctionFk: ailmentId,
          'body_part_id': bpId,
        };
      }).toList();

      await client.from(_junctionTable).insert(rowsToInsert);
    }
  }

  // ============================================================
  // BACKWARD-COMPATIBLE ALIASES
  // ============================================================
  Future<List<AilmentModel>> getAllConditions() => getAllAilments();
  Future<int> getConditionsCount() => getAilmentsCount();
  Future<AilmentModel?> getConditionById(String id) => getAilmentById(id);
  Future<List<AilmentModel>> getConditionsByAilmentCategory(AilmentCategory cat) =>
      getAilmentsByCategory(cat);
  Future<List<AilmentModel>> getConditionsByBodySystem(BodySystem sys) =>
      getAilmentsByCategory(sys);
  Future<List<AilmentModel>> getConditionsByBodyPart(String bpId) =>
      getAilmentsByBodyPart(bpId);
  Future<List<AilmentModel>> searchConditions(String q) => searchAilments(q);
  Future<AilmentModel> createCondition(AilmentModel m, {List<String>? bodyPartIds}) =>
      createAilment(m, bodyPartIds: bodyPartIds);
  Future<AilmentModel> updateCondition(AilmentModel m, {List<String>? bodyPartIds}) =>
      updateAilment(m, bodyPartIds: bodyPartIds);
  Future<void> deleteCondition(String id) => deleteAilment(id);
}

/// Backward-compatible alias for legacy ConditionRemoteDataSource
typedef ConditionRemoteDataSource = AilmentRemoteDataSource;
