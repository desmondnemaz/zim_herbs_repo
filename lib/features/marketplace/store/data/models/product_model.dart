import 'package:zim_herbs_repo/core/models/record_audit_entry.dart';
import 'package:zim_herbs_repo/core/utils/enums.dart';

class ProductModel {
  final String id;
  final String name;
  final String price;
  final String imageUrl;
  final String description;
  final String category;
  final String supplierName;
  final String supplierLocation;
  final double rating;
  final int reviewsCount;

  // Validation Pipeline Fields
  final RecordValidationStatus validationStatus;
  final String? submittedBy;
  final DateTime? submittedAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? validatedBy;
  final DateTime? validatedAt;
  final String? publishedBy;
  final DateTime? publishedAt;
  final String? rejectedBy;
  final DateTime? rejectedAt;
  final String? rejectionReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.description,
    required this.category,
    required this.supplierName,
    required this.supplierLocation,
    this.rating = 4.8,
    this.reviewsCount = 24,
    this.validationStatus = RecordValidationStatus.published,
    this.submittedBy,
    this.submittedAt,
    this.reviewedBy,
    this.reviewedAt,
    this.validatedBy,
    this.validatedAt,
    this.publishedBy,
    this.publishedAt,
    this.rejectedBy,
    this.rejectedAt,
    this.rejectionReason,
    this.createdAt,
    this.updatedAt,
  });

  /// Computes the chronological validation history timeline.
  List<RecordAuditEntry> get auditHistory {
    final status = validationStatus;
    final isRej = status == RecordValidationStatus.rejected;

    return [
      RecordAuditEntry(
        stage: RecordValidationStatus.submitted,
        actorId: submittedBy ?? supplierName,
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
        actorId: validatedBy,
        timestamp: validatedAt,
        isCompleted: status.stepIndex >= 3 && !isRej,
        isCurrent: status == RecordValidationStatus.validated,
      ),
      if (!isRej)
        RecordAuditEntry(
          stage: RecordValidationStatus.published,
          actorId: publishedBy ?? validatedBy,
          timestamp: publishedAt ?? validatedAt,
          isCompleted: status == RecordValidationStatus.published,
          isCurrent: status == RecordValidationStatus.published,
        )
      else
        RecordAuditEntry(
          stage: RecordValidationStatus.rejected,
          actorId: rejectedBy,
          timestamp: rejectedAt ?? updatedAt,
          notes: rejectionReason,
          isCompleted: true,
          isCurrent: true,
        ),
    ];
  }

  ProductModel copyWith({
    String? id,
    String? name,
    String? price,
    String? imageUrl,
    String? description,
    String? category,
    String? supplierName,
    String? supplierLocation,
    double? rating,
    int? reviewsCount,
    RecordValidationStatus? validationStatus,
    String? submittedBy,
    DateTime? submittedAt,
    String? reviewedBy,
    DateTime? reviewedAt,
    String? validatedBy,
    DateTime? validatedAt,
    String? publishedBy,
    DateTime? publishedAt,
    String? rejectedBy,
    DateTime? rejectedAt,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      category: category ?? this.category,
      supplierName: supplierName ?? this.supplierName,
      supplierLocation: supplierLocation ?? this.supplierLocation,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      validationStatus: validationStatus ?? this.validationStatus,
      submittedBy: submittedBy ?? this.submittedBy,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      validatedBy: validatedBy ?? this.validatedBy,
      validatedAt: validatedAt ?? this.validatedAt,
      publishedBy: publishedBy ?? this.publishedBy,
      publishedAt: publishedAt ?? this.publishedAt,
      rejectedBy: rejectedBy ?? this.rejectedBy,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

