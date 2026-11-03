/// Domain Entities for the Herb Feature.
///
/// Pure business entities independent of any database or framework.
library;

import 'package:zim_herbs_repo/core/models/record_audit_entry.dart';
import 'package:zim_herbs_repo/core/utils/enums.dart';
import 'package:zim_herbs_repo/features/repository/herbs/domain/entities/herb_other_use.dart';

export 'herb_other_use.dart';

class HerbImage {
  final String id;
  final String herbId;
  final String imageUrl;
  final String? description;
  final int orderIndex;

  const HerbImage({
    required this.id,
    required this.herbId,
    required this.imageUrl,
    this.description,
    this.orderIndex = 0,
  });
}

class Herb {
  final String id;
  final String nameEn;
  final String? nameSn;
  final String? nameNd;
  final String? scientificName;
  final String? family;
  final String? growthHabit;
  final List<String> partsUsed;
  final String? placesFound;
  final String? exoticStatus;
  final String? description;
  final bool isApproved;
  final RecordValidationStatus validationStatus;
  final List<HerbImage> images;
  final List<HerbOtherUse> otherUses;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final String? moderationNotes;

  // Granular stage tracking
  final String? submittedBy;
  final DateTime? submittedAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? publishedBy;
  final DateTime? publishedAt;
  final String? rejectedBy;
  final DateTime? rejectedAt;
  final String? rejectionReason;

  const Herb({
    required this.id,
    required this.nameEn,
    this.nameSn,
    this.nameNd,
    this.scientificName,
    this.family,
    this.growthHabit,
    this.partsUsed = const [],
    this.placesFound,
    this.exoticStatus = 'Indigenous',
    this.description,
    this.isApproved = true,
    this.validationStatus = RecordValidationStatus.published,
    this.images = const [],
    this.otherUses = const [],
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.verifiedBy,
    this.verifiedAt,
    this.moderationNotes,
    this.submittedBy,
    this.submittedAt,
    this.reviewedBy,
    this.reviewedAt,
    this.publishedBy,
    this.publishedAt,
    this.rejectedBy,
    this.rejectedAt,
    this.rejectionReason,
  });

  /// URL of the primary/first image (if available).
  String? get primaryImageUrl =>
      images.isNotEmpty ? images.first.imageUrl : null;

  /// User-facing display name.
  String get displayName => nameEn;

  /// Computes the chronological validation history timeline.
  List<RecordAuditEntry> get auditHistory {
    final status = validationStatus;
    final isRej = status == RecordValidationStatus.rejected;

    return [
      RecordAuditEntry(
        stage: RecordValidationStatus.submitted,
        actorId: submittedBy ?? createdBy,
        timestamp: submittedAt ?? createdAt,
        isCompleted: true,
        isCurrent: status == RecordValidationStatus.submitted,
      ),
      RecordAuditEntry(
        stage: RecordValidationStatus.underReview,
        actorId: reviewedBy,
        timestamp: reviewedAt,
        isCompleted: status.stepIndex >= 2 && !isRej,
        isCurrent: status == RecordValidationStatus.underReview,
      ),
      RecordAuditEntry(
        stage: RecordValidationStatus.validated,
        actorId: verifiedBy,
        timestamp: verifiedAt,
        isCompleted: status.stepIndex >= 3 && !isRej,
        isCurrent: status == RecordValidationStatus.validated,
      ),
      if (!isRej)
        RecordAuditEntry(
          stage: RecordValidationStatus.published,
          actorId: publishedBy ?? verifiedBy,
          timestamp: publishedAt ?? verifiedAt,
          isCompleted: status == RecordValidationStatus.published,
          isCurrent: status == RecordValidationStatus.published,
        )
      else
        RecordAuditEntry(
          stage: RecordValidationStatus.rejected,
          actorId: rejectedBy,
          timestamp: rejectedAt ?? updatedAt,
          notes: rejectionReason ?? moderationNotes,
          isCompleted: true,
          isCurrent: true,
        ),
    ];
  }
}
