/// Models for Supabase database tables.
///
/// This file belongs to the DATA layer.
///
/// The model's job is to represent data coming from
/// Supabase and convert that data into Dart objects.
///
/// In our architecture:
///
/// Supabase
///    ↓
/// RemoteDataSource
///    ↓
/// HerbModel  ← this file
///    ↓
/// Herb Entity
///    ↓
/// Domain / Cubit
library;

import 'package:zim_herbs_repo/core/models/record_audit_entry.dart';
import 'package:zim_herbs_repo/core/utils/enums.dart';
import 'package:zim_herbs_repo/features/repository/remedies/data/models/remedy_model.dart';
import 'herb_other_use_model.dart';

/// Import the DOMAIN entity.
///
/// IMPORTANT:
/// HerbModel belongs to DATA.
/// Herb belongs to DOMAIN.
///
/// We use this entity so that the domain layer
/// does not have to depend directly on Supabase models.
import '../../domain/entities/herb.dart';


/// ============================================================
/// HERB MODEL
/// ============================================================
///
/// HerbModel represents the `herbs` table in Supabase.
///
/// It is responsible for:
/// - Reading Supabase JSON
/// - Converting JSON → HerbModel
/// - Converting HerbModel → JSON
/// - Holding database-related data such as images and treatments
///
/// This is a DATA-layer class.
class HerbModel {

  /// The unique ID of the herb.
  final String id;

  /// English name of the herb.
  final String nameEn;

  /// Optional Shona name.
  final String? nameSn;

  /// Optional Ndebele name.
  final String? nameNd;

  /// Botanical/scientific binomial name (e.g. Lippia javanica).
  final String? scientificName;

  /// Plant family (e.g. Verbenaceae).
  final String? family;

  /// Growth habit (e.g. Tree, Shrub, Herb, Climber).
  final String? growthHabit;

  /// Parts of the plant used (e.g. Leaves, Roots, Bark).
  final List<String> partsUsed;

  /// Where found / geographic distribution.
  final String? placesFound;

  /// Exotic status (Indigenous, Naturalized, Exotic, Invasive).
  final String? exoticStatus;

  /// Optional description of the herb.
  final String? description;

  /// Whether the herb has been verified by moderators.
  final bool isApproved;

  /// Multi-stage validation status (submitted -> under_review -> validated -> published / rejected).
  final RecordValidationStatus validationStatus;

  /// When the herb was created in Supabase.
  final DateTime? createdAt;

  /// When the herb was last updated.
  final DateTime? updatedAt;

  /// Contributor/user who created this record.
  final String? createdBy;

  /// User who last updated this record.
  final String? updatedBy;

  /// Moderator/admin who verified this herb.
  final String? verifiedBy;

  /// Timestamp when this herb was verified.
  final DateTime? verifiedAt;

  /// Notes or reason provided during moderation.
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

  /// Images belonging to this herb.
  ///
  /// We use another model:
  /// HerbImageModel
  final List<HerbImageModel> images;

  /// Other non-medicinal uses belonging to this herb.
  final List<HerbOtherUseModel> otherUses;

  /// Remedies associated with this herb.
  final List<RemedyModel> remedies;

  /// Backwards-compatible alias for remedies.
  List<RemedyModel> get treatments => remedies;

  /// Constructor for creating a HerbModel manually.
  HerbModel({
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
    this.isApproved = false,
    this.validationStatus = RecordValidationStatus.submitted,
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
    this.images = const [],
    this.otherUses = const [],
    List<RemedyModel>? remedies,
    List<RemedyModel>? treatments,
  }) : remedies = remedies ?? treatments ?? const [];


  /// ==========================================================
  /// MODEL → ENTITY
  /// ==========================================================
  ///
  /// This method converts a DATA object (HerbModel)
  /// into a DOMAIN object (Herb).
  ///
  /// Why do we need this?
  ///
  /// Our Domain layer should not care whether our data
  /// comes from:
  ///
  /// - Supabase
  /// - Firebase
  /// - REST API
  /// - Local database
  ///
  /// The Domain layer works with the `Herb` entity.
  ///
  /// Therefore:
  ///
  /// HerbModel
  ///     ↓
  /// toEntity()
  ///     ↓
  /// Herb
  Herb toEntity() {
    return Herb(
      id: id,
      nameEn: nameEn,
      nameSn: nameSn,
      nameNd: nameNd,
      scientificName: scientificName,
      family: family,
      growthHabit: growthHabit,
      partsUsed: partsUsed,
      placesFound: placesFound,
      exoticStatus: exoticStatus,
      description: description,
      isApproved: isApproved,
      validationStatus: validationStatus,
      images: images.map((image) => image.toEntity()).toList(),
      otherUses: otherUses.map((u) => u.toEntity()).toList(),
      createdAt: createdAt,
      updatedAt: updatedAt,
      createdBy: createdBy,
      updatedBy: updatedBy,
      verifiedBy: verifiedBy,
      verifiedAt: verifiedAt,
      moderationNotes: moderationNotes,
      submittedBy: submittedBy,
      submittedAt: submittedAt,
      reviewedBy: reviewedBy,
      reviewedAt: reviewedAt,
      publishedBy: publishedBy,
      publishedAt: publishedAt,
      rejectedBy: rejectedBy,
      rejectedAt: rejectedAt,
      rejectionReason: rejectionReason,
    );
  }


  /// ==========================================================
  /// ENTITY → MODEL
  /// ==========================================================
  ///
  /// This is the opposite of `toEntity()`.
  ///
  /// It converts a DOMAIN entity into a DATA model.
  ///
  /// Example:
  ///
  /// Herb
  ///   ↓
  /// fromEntity()
  ///   ↓
  /// HerbModel
  ///
  /// This becomes useful when we want to send domain data
  /// back to the database.
  factory HerbModel.fromEntity(Herb herb) {
    return HerbModel(
      id: herb.id,
      nameEn: herb.nameEn,
      nameSn: herb.nameSn,
      nameNd: herb.nameNd,
      scientificName: herb.scientificName,
      family: herb.family,
      growthHabit: herb.growthHabit,
      partsUsed: herb.partsUsed,
      placesFound: herb.placesFound,
      exoticStatus: herb.exoticStatus,
      description: herb.description,
      isApproved: herb.isApproved,
      validationStatus: herb.validationStatus,
      images: herb.images.map((img) => HerbImageModel.fromEntity(img)).toList(),
      otherUses: herb.otherUses.map((u) => HerbOtherUseModel.fromEntity(u)).toList(),
      createdAt: herb.createdAt,
      updatedAt: herb.updatedAt,
      createdBy: herb.createdBy,
      updatedBy: herb.updatedBy,
      verifiedBy: herb.verifiedBy,
      verifiedAt: herb.verifiedAt,
      moderationNotes: herb.moderationNotes,
      submittedBy: herb.submittedBy,
      submittedAt: herb.submittedAt,
      reviewedBy: herb.reviewedBy,
      reviewedAt: herb.reviewedAt,
      publishedBy: herb.publishedBy,
      publishedAt: herb.publishedAt,
      rejectedBy: herb.rejectedBy,
      rejectedAt: herb.rejectedAt,
      rejectionReason: herb.rejectionReason,
    );
  }


  /// ==========================================================
  /// JSON → MODEL
  /// ==========================================================
  ///
  /// Supabase returns data as JSON-like Maps.
  ///
  /// Example:
  ///
  /// {
  ///   "id": "123",
  ///   "name_en": "Moringa",
  ///   "name_sn": "Mufushwa"
  /// }
  ///
  /// `fromJson()` converts that database response
  /// into a Dart HerbModel object.
  ///
  /// This is one of the most important methods
  /// in the DATA layer.
  factory HerbModel.fromJson(Map<String, dynamic> json) {

    /// Extract herb images from the Supabase response.
    ///
    /// If `herb_images` does not exist,
    /// use an empty list instead.
    final images =
        (json['herb_images'] as List<dynamic>?)
            ?.map(
              (e) => HerbImageModel.fromJson(
                e as Map<String, dynamic>,
              ),
            )
            .toList() ??
        [];

    /// Sort images according to their order index.
    ///
    /// This allows us to determine which image
    /// should appear first.
    images.sort(
      (a, b) => a.orderIndex.compareTo(b.orderIndex),
    );


    /// Create and return the HerbModel.
    return HerbModel(
      /// Convert the JSON `id` into a String.
      id: json['id'] as String,

      /// Convert `name_en` into a String.
      nameEn: json['name_en'] as String,

      /// Shona name can be null.
      nameSn: json['name_sn'] as String?,

      /// Ndebele name can be null.
      nameNd: json['name_nd'] as String?,

      /// Botanical & ecological fields
      scientificName: json['scientific_name'] as String?,
      family: json['family'] as String?,
      growthHabit: json['growth_habit'] as String?,
      partsUsed: json['parts_used'] is List
          ? (json['parts_used'] as List).map((e) => e.toString()).toList()
          : (json['parts_used'] is String && (json['parts_used'] as String).isNotEmpty
              ? (json['parts_used'] as String).split(',').map((s) => s.trim()).toList()
              : const <String>[]),
      placesFound: json['places_found'] as String?,
      exoticStatus: json['exotic_status'] as String? ?? 'Indigenous',

      /// Description can also be null.
      description: json['description'] as String?,

      /// Convert the Supabase timestamp into DateTime.
      ///
      /// If there is no timestamp, keep it null.
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(
                  json['created_at'] as String,
                )
              : null,

      /// Whether the herb is approved by moderators.
      isApproved: json['is_approved'] == true,

      /// Multi-stage validation status
      validationStatus: RecordValidationStatus.fromString(
        json['validation_status'] as String?,
        isApproved: json['is_approved'] == true,
      ),

      /// Same process for updated_at.
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(
                  json['updated_at'] as String,
                )
              : null,

      /// Audit attribution fields
      createdBy: json['created_by'] as String?,
      updatedBy: json['updated_by'] as String?,
      verifiedBy: json['verified_by'] as String?,
      verifiedAt: json['verified_at'] != null
          ? DateTime.tryParse(json['verified_at'] as String)
          : null,
      moderationNotes: json['moderation_notes'] as String?,

      // Granular stage tracking
      submittedBy: json['submitted_by'] as String?,
      submittedAt: json['submitted_at'] != null
          ? DateTime.tryParse(json['submitted_at'] as String)
          : null,
      reviewedBy: json['reviewed_by'] as String?,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.tryParse(json['reviewed_at'] as String)
          : null,
      publishedBy: json['published_by'] as String?,
      publishedAt: json['published_at'] != null
          ? DateTime.tryParse(json['published_at'] as String)
          : null,
      rejectedBy: json['rejected_by'] as String?,
      rejectedAt: json['rejected_at'] != null
          ? DateTime.tryParse(json['rejected_at'] as String)
          : null,
      rejectionReason:
          (json['rejection_reason'] ?? json['moderation_notes']) as String?,

      /// Attach the images we extracted above.
      images: images,

      /// Non-medicinal other uses
      otherUses: (json['herb_other_uses'] as List<dynamic>?)
              ?.map((e) => HerbOtherUseModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],

      /// Extract remedy information.
      ///
      /// Supabase returns:
      ///
      /// remedy_herbs
      ///       ↓
      /// remedies
      ///
      /// Therefore we go inside the relationship
      /// to get the actual remedy object.
      remedies:
          ((json['remedy_herbs'] ?? json['treatment_herbs']) as List<dynamic>?)
              ?.map((e) {
                final remedyJson =
                    (e['remedies'] ?? e['treatments'])
                        as Map<String, dynamic>?;

                if (remedyJson == null) {
                  return null;
                }

                return RemedyModel.fromJson(
                  remedyJson,
                );
              })
              .whereType<RemedyModel>()
              .toList() ??
          [],
    );
  }


  /// ==========================================================
  /// MODEL → JSON
  /// ==========================================================
  ///
  /// Converts HerbModel back into a Map.
  ///
  /// This is useful when inserting or updating
  /// records in Supabase.
  ///
  /// Example:
  ///
  /// HerbModel
  ///    ↓
  /// toJson()
  ///    ↓
  /// A Map containing String keys and dynamic values.
  ///    ↓
  /// Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_en': nameEn,
      'name_sn': nameSn,
      'name_nd': nameNd,
      if (scientificName != null) 'scientific_name': scientificName,
      if (family != null) 'family': family,
      if (growthHabit != null) 'growth_habit': growthHabit,
      'parts_used': partsUsed,
      if (placesFound != null) 'places_found': placesFound,
      if (exoticStatus != null) 'exotic_status': exoticStatus,
      'description': description,
      'is_approved': isApproved,
      'validation_status': validationStatus.dbValue,
      if (createdBy != null) 'created_by': createdBy,
      if (updatedBy != null) 'updated_by': updatedBy,
      if (verifiedBy != null) 'verified_by': verifiedBy,
      if (verifiedAt != null) 'verified_at': verifiedAt!.toIso8601String(),
      if (moderationNotes != null) 'moderation_notes': moderationNotes,
      if (submittedBy != null) 'submitted_by': submittedBy,
      if (submittedAt != null) 'submitted_at': submittedAt!.toIso8601String(),
      if (reviewedBy != null) 'reviewed_by': reviewedBy,
      if (reviewedAt != null) 'reviewed_at': reviewedAt!.toIso8601String(),
      if (publishedBy != null) 'published_by': publishedBy,
      if (publishedAt != null) 'published_at': publishedAt!.toIso8601String(),
      if (rejectedBy != null) 'rejected_by': rejectedBy,
      if (rejectedAt != null) 'rejected_at': rejectedAt!.toIso8601String(),
      if (rejectionReason != null) 'rejection_reason': rejectionReason,
    };
  }


  /// ==========================================================
  /// PRIMARY IMAGE
  /// ==========================================================
  ///
  /// Returns the first/primary image of the herb.
  ///
  /// If there are no images,
  /// return null.
  String? get primaryImageUrl {

    /// No images = no primary image.
    if (images.isEmpty) {
      return null;
    }

    /// Create a copy of the images list
    /// so that we don't modify the original list.
    final sorted = List<HerbImageModel>.from(images)

      /// Sort images using their order index.
      ..sort(
        (a, b) =>
            a.orderIndex.compareTo(b.orderIndex),
      );

    /// Return the URL of the first image.
    return sorted.first.imageUrl;
  }


  /// ==========================================================
  /// DISPLAY NAME
  /// ==========================================================
  ///
  /// A convenient getter used by the UI.
  ///
  /// For now we simply display the English name.
  String get displayName => nameEn;

  /// Convenience getter for the verification and lifecycle audit history
  List<RecordAuditEntry> get auditHistory => toEntity().auditHistory;
}


/// ============================================================
/// HERB IMAGE MODEL
/// ============================================================
///
/// Represents a record from the `herb_images` table.
///
/// This is also part of the DATA layer.
class HerbImageModel {

  /// Unique ID of the image record.
  final String id;

  /// ID of the herb this image belongs to.
  final String herbId;

  /// URL of the image.
  final String imageUrl;

  /// Optional image description.
  final String? description;

  /// Determines the order in which images appear.
  final int orderIndex;


  /// Constructor.
  HerbImageModel({
    required this.id,
    required this.herbId,
    required this.imageUrl,
    this.description,
    this.orderIndex = 0,
  });


  /// ==========================================================
  /// JSON → HERB IMAGE MODEL
  /// ==========================================================
  ///
  /// Converts Supabase JSON into HerbImageModel.
  factory HerbImageModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return HerbImageModel(
      id: json['id'] as String,
      herbId: json['herb_id'] as String,
      imageUrl: json['image_url'] as String,
      description: json['description'] as String?,
      orderIndex:
          json['order_index'] as int? ?? 0,
    );
  }


  /// ==========================================================
  /// HERB IMAGE MODEL → JSON
  /// ==========================================================
  ///
  /// Converts the Dart object into a Map
  /// that can be sent to Supabase.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'herb_id': herbId,
      'image_url': imageUrl,
      'description': description,
      'order_index': orderIndex,
    };
  }

  /// Convert Data Model to Domain Entity
  HerbImage toEntity() {
    return HerbImage(
      id: id,
      herbId: herbId,
      imageUrl: imageUrl,
      description: description,
      orderIndex: orderIndex,
    );
  }

  /// Convert Domain Entity to Data Model
  factory HerbImageModel.fromEntity(HerbImage image) {
    return HerbImageModel(
      id: image.id,
      herbId: image.herbId,
      imageUrl: image.imageUrl,
      description: image.description,
      orderIndex: image.orderIndex,
    );
  }
}