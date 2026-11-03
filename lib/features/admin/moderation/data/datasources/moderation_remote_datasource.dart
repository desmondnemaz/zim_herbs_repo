import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zim_herbs_repo/core/utils/enums.dart';
import 'package:zim_herbs_repo/features/repository/herbs/data/models/herb_model.dart';
import 'package:zim_herbs_repo/features/repository/remedies/data/models/remedy_model.dart';
import '../models/herbalist_moderation_model.dart';
import '../models/supplier_moderation_model.dart';

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
      query = query.neq('validation_status', RecordValidationStatus.published.dbValue);
    }

    final response = await query.order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((json) => HerbModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Approve or revoke approval of a herb
  Future<void> updateHerbApproval(
    String herbId,
    bool isApproved, {
    String? moderatorId,
    String? comments,
  }) async {
    final now = DateTime.now().toIso8601String();
    final updateData = <String, dynamic>{
      'validation_status': isApproved
          ? RecordValidationStatus.published.dbValue
          : RecordValidationStatus.rejected.dbValue,
      'updated_at': now,
    };

    if (moderatorId != null) {
      if (isApproved) {
        updateData['verified_by'] = moderatorId;
        updateData['verified_at'] = now;
        updateData['published_by'] = moderatorId;
        updateData['published_at'] = now;
      } else {
        updateData['rejected_by'] = moderatorId;
        updateData['rejected_at'] = now;
      }
    }
    if (comments != null) {
      updateData['moderation_notes'] = comments;
      updateData['rejection_reason'] = comments;
    }

    await client.from('herbs').update(updateData).eq('id', herbId);
  }

  /// Advances or transitions herb validation status (submitted, under_review, validated, published, rejected)
  Future<void> updateHerbValidationStatus(
    String herbId,
    RecordValidationStatus status, {
    String? moderatorId,
    String? reason,
  }) async {
    final now = DateTime.now().toIso8601String();
    final updateData = <String, dynamic>{
      'validation_status': status.dbValue,
      'updated_at': now,
    };

    switch (status) {
      case RecordValidationStatus.underReview:
        updateData['reviewed_by'] = moderatorId;
        updateData['reviewed_at'] = now;
        break;
      case RecordValidationStatus.validated:
        updateData['verified_by'] = moderatorId;
        updateData['verified_at'] = now;
        break;
      case RecordValidationStatus.published:
        updateData['published_by'] = moderatorId;
        updateData['published_at'] = now;
        updateData['verified_by'] = moderatorId;
        updateData['verified_at'] = now;
        break;
      case RecordValidationStatus.rejected:
        updateData['rejected_by'] = moderatorId;
        updateData['rejected_at'] = now;
        updateData['rejection_reason'] = reason;
        updateData['moderation_notes'] = reason;
        break;
      case RecordValidationStatus.submitted:
      case RecordValidationStatus.draft:
      case RecordValidationStatus.archived:
        break;
    }

    await client.from('herbs').update(updateData).eq('id', herbId);
  }

  /// Delete a herb (e.g. invalid or spam submission)
  Future<void> deleteHerb(String herbId) async {
    await client.from('herbs').delete().eq('id', herbId);
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
      query = query.neq('validation_status', RecordValidationStatus.published.dbValue);
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
      'validation_status': isApproved
          ? RecordValidationStatus.published.dbValue
          : RecordValidationStatus.rejected.dbValue,
      'moderation_comments': comments,
      'rejection_reason': comments,
      'updated_at': now,
    };

    if (isApproved) {
      updateData['approved_by'] = moderatorId;
      updateData['approved_at'] = now;
      updateData['published_by'] = moderatorId;
      updateData['published_at'] = now;
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

  /// Advances or transitions remedy validation status (submitted, under_review, validated, published, rejected)
  Future<void> updateRemedyValidationStatus(
    String remedyId,
    RecordValidationStatus status, {
    String? moderatorId,
    String? reason,
  }) async {
    final now = DateTime.now().toIso8601String();
    final updateData = <String, dynamic>{
      'validation_status': status.dbValue,
      'updated_at': now,
    };

    switch (status) {
      case RecordValidationStatus.underReview:
        updateData['reviewed_by'] = moderatorId;
        updateData['reviewed_at'] = now;
        break;
      case RecordValidationStatus.validated:
        updateData['validated_by'] = moderatorId;
        updateData['validated_at'] = now;
        break;
      case RecordValidationStatus.published:
        updateData['published_by'] = moderatorId;
        updateData['published_at'] = now;
        updateData['approved_by'] = moderatorId;
        updateData['approved_at'] = now;
        break;
      case RecordValidationStatus.rejected:
        updateData['rejected_by'] = moderatorId;
        updateData['rejected_at'] = now;
        updateData['rejection_reason'] = reason;
        updateData['moderation_comments'] = reason;
        break;
      case RecordValidationStatus.submitted:
      case RecordValidationStatus.draft:
      case RecordValidationStatus.archived:
        break;
    }

    await client.from('remedies').update(updateData).eq('id', remedyId);
  }

  /// Delete a remedy (e.g. invalid or duplicate submission)
  Future<void> deleteRemedy(String remedyId) async {
    await client.from('remedies').delete().eq('id', remedyId);
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

    // 2. Synchronize is_practitioner and primary_role in user_profiles
    final isPractitioner = normalizedStatus == 'verified';
    try {
      final updateData = <String, dynamic>{
        'is_practitioner': isPractitioner,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (isPractitioner) {
        updateData['primary_role'] = 'practitioner';
      }
      await client.from('user_profiles').update(updateData).eq('id', herbalistId);
    } catch (_) {
      // If user profile sync fails, herbalist_profile status still persists
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 4. Botanical Supplier Moderation & Publishing
  // ───────────────────────────────────────────────────────────────────────────

  /// Fetch botanical supplier applications/profiles for review
  Future<List<SupplierModerationModel>> getSuppliersForModeration({
    String? statusFilter,
  }) async {
    var query = client.from('supplier_profiles').select('''
          *,
          user_profiles(
            id,
            full_name,
            username,
            email,
            avatar_url,
            phone_number,
            bio
          )
        ''');

    if (statusFilter != null && statusFilter.isNotEmpty) {
      query = query.eq('verification_status', statusFilter.toLowerCase());
    }

    final response = await query.order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((json) =>
            SupplierModerationModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Verify and approve (publish) or reject a supplier profile
  Future<void> updateSupplierStatus(
    String supplierId,
    String status,
  ) async {
    final normalizedStatus = status.toLowerCase();

    // 1. Update verification_status in supplier_profiles
    await client.from('supplier_profiles').update({
      'verification_status': normalizedStatus,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', supplierId);

    // 2. Synchronize is_supplier and primary_role in user_profiles (approving publishes the supplier!)
    final isSupplier = normalizedStatus == 'verified';
    try {
      final updateData = <String, dynamic>{
        'is_supplier': isSupplier,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (isSupplier) {
        updateData['primary_role'] = 'supplier';
      }
      await client.from('user_profiles').update(updateData).eq('id', supplierId);
    } catch (_) {
      // If user profile sync fails, supplier_profiles status still persists
    }
  }
}
