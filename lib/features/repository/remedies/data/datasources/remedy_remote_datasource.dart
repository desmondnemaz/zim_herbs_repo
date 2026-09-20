import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/remedy_model.dart';

/// Communicates directly with the Supabase `remedies` table.
///
/// This is the DATA layer — it knows about Supabase.
/// All other layers receive data through this class.
class RemedyRemoteDataSource {
  final SupabaseClient client;

  RemedyRemoteDataSource(this.client);

  // ============================================================
  // GET ALL REMEDIES
  // ============================================================

  /// Fetch all remedies with their conditions and herbs.
  Future<List<RemedyModel>> getAllRemedies() async {
    final response = await client
        .from('remedies')
        .select('''
          *,
          conditions(*),
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
    final response =
        await client
            .from('remedies')
            .select('''
          *,
          conditions(*),
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

  /// Search remedies by name or condition name.
  Future<List<RemedyModel>> searchRemedies(String query) async {
    final response = await client
        .from('remedies')
        .select('''
          *,
          conditions!inner(*),
          remedy_herbs(*, herbs(*, herb_images(*)))
        ''')
        .or('name.ilike.%$query%,conditions.name.ilike.%$query%')
        .order('name');

    return (response as List<dynamic>)
        .map((json) => RemedyModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // GET REMEDIES BY CONDITION
  // ============================================================

  /// Get remedies for a specific condition.
  Future<List<RemedyModel>> getRemediesByCondition(
    String conditionId,
  ) async {
    final response = await client
        .from('remedies')
        .select('''
          *,
          conditions!inner(*),
          remedy_herbs(*, herbs(*, herb_images(*)))
        ''')
        .eq('condition_id', conditionId)
        .order('name');

    return (response as List<dynamic>)
        .map((json) => RemedyModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // GET REMEDIES BY HERB
  // ============================================================

  /// Get remedies that use a specific herb.
  Future<List<RemedyModel>> getRemediesByHerbId(String herbId) async {
    final response = await client
        .from('remedies')
        .select('''
          *,
          conditions(*),
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
  Future<void> deleteRemedy(String id) async {
    await client.from('remedies').delete().eq('id', id);
  }

  // ============================================================
  // APPROVE REMEDY
  // ============================================================

  /// Approve or disapprove a remedy.
  Future<void> approveRemedy(String id, {bool approved = true}) async {
    await client
        .from('remedies')
        .update({'is_approved': approved})
        .eq('id', id);
  }
}
