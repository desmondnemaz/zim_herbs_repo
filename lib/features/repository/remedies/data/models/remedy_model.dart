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
/// RemedyModel  ← this file
///    ↓
/// Remedy Entity
///    ↓
/// Domain / Cubit
library;

import 'package:zim_herbs_repo/features/repository/conditions/data/models/condition_model.dart';
import 'package:zim_herbs_repo/features/repository/herbs/data/models/herb_model.dart';
import '../../domain/entities/remedy.dart';

// ============================================================
// REMEDY MODEL
// ============================================================
class RemedyModel {
  final String id;
  final String conditionId;
  final String name;
  final String methodOfUse;
  final String preparation;

  final String? dosageInfants;
  final String? dosageAdults;
  final String? duration;
  final String? frequency;
  final String? notes;
  final String? precautions;
  final String? sideEffects;
  final String? disclaimer;

  final bool isApproved;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? moderationComments;
  final DateTime? rejectedAt;
  final String? rejectedBy;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  final ConditionModel? condition;
  final List<RemedyHerbModel> remedyHerbs;

  RemedyModel({
    required this.id,
    required this.conditionId,
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
    this.isApproved = false,
    this.approvedBy,
    this.approvedAt,
    this.moderationComments,
    this.rejectedAt,
    this.rejectedBy,
    this.createdAt,
    this.updatedAt,
    this.condition,
    this.remedyHerbs = const [],
  });

  // ==========================================================
  // JSON → MODEL
  // ==========================================================
  factory RemedyModel.fromJson(Map<String, dynamic> json) {
    // Check for 'remedy_herbs' first, fallback to 'treatment_herbs'
    final rawHerbs = (json['remedy_herbs'] ?? json['treatment_herbs']) as List<dynamic>?;

    return RemedyModel(
      id: json['id'] as String,
      conditionId: json['condition_id'] as String,
      name: json['name'] as String? ?? 'Unnamed Remedy',
      methodOfUse: json['method_of_use'] as String? ?? '',
      preparation: json['preparation'] as String? ?? '',
      dosageInfants: json['dosage_infants'] as String?,
      dosageAdults: json['dosage_adults'] as String?,
      duration: json['duration'] as String?,
      frequency: json['frequency'] as String?,
      notes: json['notes'] as String?,
      precautions: json['precautions'] as String?,
      sideEffects: json['side_effects'] as String?,
      disclaimer: json['disclaimer'] as String?,
      isApproved: json['is_approved'] as bool? ?? false,
      approvedBy: json['approved_by'] as String?,
      approvedAt:
          json['approved_at'] != null
              ? DateTime.parse(json['approved_at'] as String)
              : null,
      moderationComments: json['moderation_comments'] as String?,
      rejectedAt:
          json['rejected_at'] != null
              ? DateTime.parse(json['rejected_at'] as String)
              : null,
      rejectedBy: json['rejected_by'] as String?,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : null,
      condition:
          json['conditions'] != null
              ? ConditionModel.fromJson(
                json['conditions'] as Map<String, dynamic>,
              )
              : null,
      remedyHerbs:
          rawHerbs
              ?.map(
                (e) =>
                    RemedyHerbModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  // ==========================================================
  // MODEL → JSON
  // ==========================================================
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'condition_id': conditionId,
      'name': name,
      'method_of_use': methodOfUse,
      'preparation': preparation,
      'dosage_infants': dosageInfants,
      'dosage_adults': dosageAdults,
      'duration': duration,
      'frequency': frequency,
      'notes': notes,
      'precautions': precautions,
      'side_effects': sideEffects,
      'disclaimer': disclaimer,
      'is_approved': isApproved,
      'approved_by': approvedBy,
      'moderation_comments': moderationComments,
    };
  }

  // ==========================================================
  // MODEL → ENTITY
  // ==========================================================
  Remedy toEntity() {
    return Remedy(
      id: id,
      conditionId: conditionId,
      name: name,
      methodOfUse: methodOfUse,
      preparation: preparation,
      dosageInfants: dosageInfants,
      dosageAdults: dosageAdults,
      duration: duration,
      frequency: frequency,
      notes: notes,
      precautions: precautions,
      sideEffects: sideEffects,
      disclaimer: disclaimer,
      isApproved: isApproved,
      approvedBy: approvedBy,
      approvedAt: approvedAt,
      moderationComments: moderationComments,
      rejectedAt: rejectedAt,
      rejectedBy: rejectedBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
      conditionName: condition?.name,
      conditionBodySystem: condition?.bodySystem,
      remedyHerbs:
          remedyHerbs
              .map((rh) => rh.toEntity())
              .toList(),
    );
  }

  // ==========================================================
  // ENTITY → MODEL
  // ==========================================================
  factory RemedyModel.fromEntity(Remedy remedy) {
    return RemedyModel(
      id: remedy.id,
      conditionId: remedy.conditionId,
      name: remedy.name,
      methodOfUse: remedy.methodOfUse,
      preparation: remedy.preparation,
      dosageInfants: remedy.dosageInfants,
      dosageAdults: remedy.dosageAdults,
      duration: remedy.duration,
      frequency: remedy.frequency,
      notes: remedy.notes,
      precautions: remedy.precautions,
      sideEffects: remedy.sideEffects,
      disclaimer: remedy.disclaimer,
      isApproved: remedy.isApproved,
      approvedBy: remedy.approvedBy,
      approvedAt: remedy.approvedAt,
      moderationComments: remedy.moderationComments,
      rejectedAt: remedy.rejectedAt,
      rejectedBy: remedy.rejectedBy,
      createdAt: remedy.createdAt,
      updatedAt: remedy.updatedAt,
      remedyHerbs:
          remedy.remedyHerbs
              .map((rh) => RemedyHerbModel.fromEntity(rh))
              .toList(),
    );
  }
}

// ============================================================
// REMEDY HERB MODEL
// ============================================================
class RemedyHerbModel {
  final String id;
  final String remedyId;
  final String herbId;
  final bool isMain;
  final String? quantity;
  final String? unit;
  final String? preparation;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Nested herb data from Supabase join.
  final HerbModel? herb;

  RemedyHerbModel({
    required this.id,
    required this.remedyId,
    required this.herbId,
    this.isMain = false,
    this.quantity,
    this.unit,
    this.preparation,
    this.createdAt,
    this.updatedAt,
    this.herb,
  });

  // ==========================================================
  // JSON → MODEL
  // ==========================================================
  factory RemedyHerbModel.fromJson(Map<String, dynamic> json) {
    return RemedyHerbModel(
      id: json['id'] as String,
      remedyId: (json['remedy_id'] ?? json['treatment_id'] ?? '') as String,
      herbId: json['herb_id'] as String,
      isMain: json['is_main'] as bool? ?? false,
      quantity: json['quantity'] as String?,
      unit: json['unit'] as String?,
      preparation: json['preparation'] as String?,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : null,
      herb:
          json['herbs'] != null
              ? HerbModel.fromJson(json['herbs'] as Map<String, dynamic>)
              : null,
    );
  }

  // ==========================================================
  // MODEL → JSON
  // ==========================================================
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'remedy_id': remedyId,
      'herb_id': herbId,
      'is_main': isMain,
      'quantity': quantity,
      'unit': unit,
      'preparation': preparation,
    };
  }

  // ==========================================================
  // MODEL → ENTITY
  // ==========================================================
  RemedyHerb toEntity() {
    return RemedyHerb(
      id: id,
      remedyId: remedyId,
      herbId: herbId,
      isMain: isMain,
      quantity: quantity,
      unit: unit,
      preparation: preparation,
      herbName: herb?.nameEn,
      herbImageUrl: herb?.primaryImageUrl,
    );
  }

  // ==========================================================
  // ENTITY → MODEL
  // ==========================================================
  factory RemedyHerbModel.fromEntity(RemedyHerb remedyHerb) {
    return RemedyHerbModel(
      id: remedyHerb.id,
      remedyId: remedyHerb.remedyId,
      herbId: remedyHerb.herbId,
      isMain: remedyHerb.isMain,
      quantity: remedyHerb.quantity,
      unit: remedyHerb.unit,
      preparation: remedyHerb.preparation,
    );
  }
}
