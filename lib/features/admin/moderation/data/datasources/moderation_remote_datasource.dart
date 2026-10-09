import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zim_herbs_repo/features/repository/herbs/data/models/herb_model.dart';
import 'package:zim_herbs_repo/features/repository/remedies/data/models/remedy_model.dart';
import '../models/herbalist_moderation_model.dart';

class ModerationRemoteDataSource {
  final SupabaseClient client;

  ModerationRemoteDataSource(this.client);

  // ───────────────────────────────────────────────────────────────────────────
  // 1. Herbs Moderation
  // ───────────────────────────────────────────────────────────────────────────

  /// Fetch herbs for moderation review (all or pending only)
  Future<List<HerbModel>> getHerbsForModeration({bool? pendingOnly}) async {
    var query = client
        .from('herbs')
        .select('''
          *,
          herb_images(*),
          remedy_herbs(
            *,
            remedies(
              *,
              conditions(*)
            )
          )
        ''');

    if (pendingOnly == true) {
      query = query.or('is_approved.is.false,is_approved.is.null');
    }

    final response = await query.order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((json) => HerbModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Approve or revoke approval of a herb
  Future<void> updateHerbApproval(String herbId, bool isApproved) async {
    await client.from('herbs').update({
      'is_approved': isApproved,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', herbId);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 2. Remedies Moderation
  // ───────────────────────────────────────────────────────────────────────────

  /// Fetch remedies for moderation review
  Future<List<RemedyModel>> getRemediesForModeration({bool? pendingOnly}) async {
    var query = client.from('remedies').select('''
          *,
          conditions(*),
          remedy_herbs(*, herbs(*, herb_images(*)))
        ''');

    if (pendingOnly == true) {
      query = query.or('is_approved.is.false,is_approved.is.null');
    }

    final response = await query.order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((json) => RemedyModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Approve or reject a remedy with moderator metadata and optional comments
  Future<void> updateRemedyApproval(
    String remedyId,
    bool isApproved, {
    String? moderatorId,
    String? comments,
  }) async {
    final now = DateTime.now().toIso8601String();

    final updateData = <String, dynamic>{
      'is_approved': isApproved,
      'moderation_comments': comments,
      'updated_at': now,
    };

    if (isApproved) {
      updateData['approved_by'] = moderatorId;
      updateData['approved_at'] = now;
      updateData['rejected_by'] = null;
      updateData['rejected_at'] = null;
    } else {
      updateData['rejected_by'] = moderatorId;
      updateData['rejected_at'] = now;
      updateData['approved_by'] = null;
      updateData['approved_at'] = null;
    }

    await client.from('remedies').update(updateData).eq('id', remedyId);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 3. Practitioner / Herbalist Moderation
  // ───────────────────────────────────────────────────────────────────────────

  /// Fetch herbalist practitioner applications/profiles
  Future<List<HerbalistModerationModel>> getHerbalistsForModeration({
    String? statusFilter,
  }) async {
    var query = client.from('herbalist_profiles').select('''
          *,
          user_profiles(
            id,
            full_name,
            username,
            email,
            avatar_url,
            phone_number
          )
        ''');

    if (statusFilter != null && statusFilter.isNotEmpty) {
      query = query.eq('verification_status', statusFilter.toLowerCase());
    }

    final response = await query.order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((json) =>
            HerbalistModerationModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Verify or reject an herbalist practitioner profile
  Future<void> updateHerbalistStatus(
    String herbalistId,
    String status,
  ) async {
    final normalizedStatus = status.toLowerCase();

    // 1. Update verification_status in herbalist_profiles
    await client.from('herbalist_profiles').update({
      'verification_status': normalizedStatus,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', herbalistId);

    // 2. Synchronize is_practitioner in user_profiles
    final isPractitioner = normalizedStatus == 'verified';
    try {
      await client.from('user_profiles').update({
        'is_practitioner': isPractitioner,
      }).eq('id', herbalistId);
    } catch (_) {
      // If user profile sync fails, herbalist_profile status still persists
    }
  }
}
