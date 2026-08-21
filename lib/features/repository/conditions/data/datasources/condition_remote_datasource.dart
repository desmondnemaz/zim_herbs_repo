import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zim_herbs_repo/core/utils/enums.dart';
import '../models/condition_model.dart';

class ConditionRemoteDataSource {
  final SupabaseClient client;

  ConditionRemoteDataSource(this.client);

  /// Fetch all conditions ordered by name.
  Future<List<ConditionModel>> getAllConditions() async {
    final response = await client.from('conditions').select().order('name');

    return (response as List<dynamic>)
        .map((json) => ConditionModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get total count of conditions.
  Future<int> getConditionsCount() async {
    return await client.from('conditions').count(CountOption.exact);
  }

  /// Fetch a condition by ID.
  Future<ConditionModel?> getConditionById(String id) async {
    final response =
        await client.from('conditions').select().eq('id', id).maybeSingle();

    if (response == null) return null;
    return ConditionModel.fromJson(response);
  }

  /// Fetch conditions filtered by body system.
  Future<List<ConditionModel>> getConditionsByBodySystem(
    BodySystem bodySystem,
  ) async {
    final response = await client
        .from('conditions')
        .select()
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
        .select()
        .ilike('name', '%$query%')
        .order('name');

    return (response as List<dynamic>)
        .map((json) => ConditionModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Create a new condition.
  Future<ConditionModel> createCondition(ConditionModel condition) async {
    final response =
        await client.from('conditions').insert(condition.toJson()).select().single();

    return ConditionModel.fromJson(response);
  }

  /// Update an existing condition.
  Future<ConditionModel> updateCondition(ConditionModel condition) async {
    final response = await client
        .from('conditions')
        .update(condition.toJson())
        .eq('id', condition.id)
        .select()
        .single();

    return ConditionModel.fromJson(response);
  }

  /// Delete a condition.
  Future<void> deleteCondition(String id) async {
    await client.from('conditions').delete().eq('id', id);
  }
}
