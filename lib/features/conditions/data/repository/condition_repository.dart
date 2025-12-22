import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zim_herbs_repo/features/conditions/data/repository/model.dart';
import 'package:zim_herbs_repo/utils/enums.dart';

class ConditionRepository {
  final SupabaseClient _client;

  ConditionRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  /// Fetch all conditions
  Future<List<ConditionModel>> getAllConditions() async {
    final response = await _client.from('conditions').select().order('name');

    return (response as List<dynamic>)
        .map((json) => ConditionModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get total count of conditions
  Future<int> getConditionsCount() async {
    return await _client.from('conditions').count(CountOption.exact);
  }

  /// Fetch condition by ID
  Future<ConditionModel?> getConditionById(String id) async {
    final response =
        await _client.from('conditions').select().eq('id', id).maybeSingle();

    if (response == null) return null;
    return ConditionModel.fromJson(response);
  }

  /// Fetch conditions filtered by body system
  Future<List<ConditionModel>> getConditionsByBodySystem(
    BodySystem bodySystem,
  ) async {
    final response = await _client
        .from('conditions')
        .select()
        .eq('body_system', bodySystemToString(bodySystem))
        .order('name');

    return (response as List<dynamic>)
        .map((json) => ConditionModel.fromJson(json as Map<String, dynamic>))
        .toList();
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

  /// Update an existing condition
  Future<ConditionModel> updateCondition(ConditionModel condition) async {
    final response =
        await _client
            .from('conditions')
            .update(condition.toJson())
            .eq('id', condition.id)
            .select()
            .single();

    return ConditionModel.fromJson(response);
  }

  /// Delete a condition
  Future<void> deleteCondition(String id) async {
    await _client.from('conditions').delete().eq('id', id);
  }
}
