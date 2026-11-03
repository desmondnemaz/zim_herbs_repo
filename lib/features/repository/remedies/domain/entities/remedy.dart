/// Domain Entities for the Remedy Feature.
///
/// Pure business entities independent of any database or framework.
library;

import 'package:zim_herbs_repo/core/models/record_audit_entry.dart';
import 'package:zim_herbs_repo/core/utils/enums.dart';

/// Represents a single herb used within a remedy,
/// including its role, quantity, and preparation info.
class RemedyHerb {
  final String id;
  final String remedyId;
  final String herbId;
  final bool isMain;
  final String? quantity;
  final String? unit;
  final String? preparation;

  /// Denormalised herb name for display convenience.
  final String? herbName;

  /// Denormalised herb image URL for display convenience.
  final String? herbImageUrl;

  const RemedyHerb({
    required this.id,
    required this.remedyId,
    required this.herbId,
    this.isMain = false,
    this.quantity,
    this.unit,
    this.preparation,
    this.herbName,
    this.herbImageUrl,
  });
}

/// Pure domain entity representing a Remedy.
///
/// Independent of database or serialisation concerns.
class Remedy {
  final String id;
  final String conditionId;
  final String name;
  final String methodOfUse;
  final String preparation;

  // Dosages
  final String? dosageInfants;
  final String? dosageAdults;

  // Details
  final String? duration;
  final String? frequency;
  final String? notes;
  final String? precautions;
  final String? sideEffects;
  final String? disclaimer;

  // Moderation & Validation Status
  final RecordValidationStatus validationStatus;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? moderationComments;
  final DateTime? rejectedAt;
  final String? rejectedBy;

  /// Canonical publication & approval status.
  /// Only published records are deemed approved for public use.
  bool get isApproved => validationStatus == RecordValidationStatus.published;
  bool get isPublished => validationStatus == RecordValidationStatus.published;

  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? updatedBy;

  // Granular stage tracking
  final String? submittedBy;
  final DateTime? submittedAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? publishedBy;
  final DateTime? publishedAt;
  final String? rejectionReason;

  /// Denormalised condition name for display convenience.
  final String? conditionName;

  /// Ailment aliases for condition fields
  String get ailmentId => conditionId;
  String? get ailmentName => conditionName;

  /// Denormalised condition ailment category for display/icon convenience.
  final AilmentCategory? conditionAilmentCategory;

  /// Backward-compatible alias
  AilmentCategory? get conditionBodySystem => conditionAilmentCategory;

  /// Herbs used in this remedy (domain sub-entities).
  final List<RemedyHerb> remedyHerbs;

  const Remedy({
    required this.id,
    String? conditionId,
    String? ailmentId,
    required this.name,
    required this.methodOfUse,
    required this.preparation,
    this.dosageInfants,
    this.dosageAdults,
    this.duration,
    this.frequency,
    this.notes,
    this.precautions,
    this.sideEffects,
    this.disclaimer,
    this.validationStatus = RecordValidationStatus.submitted,
    this.approvedBy,
    this.approvedAt,
    this.moderationComments,
    this.rejectedAt,
    this.rejectedBy,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.submittedBy,
    this.submittedAt,
    this.reviewedBy,
    this.reviewedAt,
    this.publishedBy,
    this.publishedAt,
    this.rejectionReason,
    String? conditionName,
    String? ailmentName,
    AilmentCategory? conditionAilmentCategory,
    AilmentCategory? conditionBodySystem,
    this.remedyHerbs = const [],
  })  : conditionId = conditionId ?? ailmentId ?? '',
        conditionName = conditionName ?? ailmentName,
        conditionAilmentCategory =
            conditionAilmentCategory ?? conditionBodySystem;

  /// User-facing display name generated from the herbs in this remedy.
  String get displayName {
    final herbNames = remedyHerbs
        .map((rh) => rh.herbName)
        .whereType<String>()
        .where((n) => n.isNotEmpty)
        .toList();

    if (herbNames.isEmpty) return name;
    return herbNames.join(' + ');
  }

  /// Computes the chronological validation history timeline.
  List<RecordAuditEntry> get auditHistory {
    final status = validationStatus;
    final isRej = status == RecordValidationStatus.rejected || rejectedBy != null;

    return [
      RecordAuditEntry(
        stage: RecordValidationStatus.submitted,
        actorId: submittedBy ?? createdBy,
        timestamp: submittedAt ?? createdAt,
        isCompleted: true,
        isCurrent: status == RecordValidationStatus.submitted && !isRej,
      ),
      RecordAuditEntry(
        stage: RecordValidationStatus.underReview,
        actorId: reviewedBy,
        timestamp: reviewedAt,
        isCompleted: status.stepIndex >= 2 && !isRej,
        isCurrent: status == RecordValidationStatus.underReview && !isRej,
      ),
      RecordAuditEntry(
        stage: RecordValidationStatus.validated,
        actorId: approvedBy,
        timestamp: approvedAt,
        isCompleted: status.stepIndex >= 3 && !isRej,
        isCurrent: status == RecordValidationStatus.validated && !isRej,
      ),
      if (!isRej)
        RecordAuditEntry(
          stage: RecordValidationStatus.published,
          actorId: publishedBy ?? approvedBy,
          timestamp: publishedAt ?? approvedAt,
          isCompleted: status == RecordValidationStatus.published,
          isCurrent: status == RecordValidationStatus.published,
        )
      else
        RecordAuditEntry(
          stage: RecordValidationStatus.rejected,
          actorId: rejectedBy,
          timestamp: rejectedAt ?? updatedAt,
          notes: rejectionReason ?? moderationComments,
          isCompleted: true,
          isCurrent: true,
        ),
    ];
  }
}
