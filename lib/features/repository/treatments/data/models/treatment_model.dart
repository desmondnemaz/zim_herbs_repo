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
/// TreatmentModel  ← this file
///    ↓
/// Treatment Entity
///    ↓
/// Domain / Cubit
library;

import 'package:zim_herbs_repo/features/repository/conditions/data/models/condition_model.dart';
import 'package:zim_herbs_repo/features/repository/herbs/data/models/herb_model.dart';
import '../../domain/entities/treatment.dart';

// ============================================================
// TREATMENT MODEL
// ============================================================
class TreatmentModel {
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
  final List<TreatmentHerbModel> treatmentHerbs;

  TreatmentModel({
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
    this.treatmentHerbs = const [],
  });

  // ==========================================================
  // JSON → MODEL
  // ==========================================================
  factory TreatmentModel.fromJson(Map<String, dynamic> json) {
    return TreatmentModel(
      id: json['id'] as String,
      conditionId: json['condition_id'] as String,
      name: json['name'] as String? ?? 'Unnamed Treatment',
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
      treatmentHerbs:
          (json['treatment_herbs'] as List<dynamic>?)
              ?.map(
                (e) =>
                    TreatmentHerbModel.fromJson(e as Map<String, dynamic>),
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
  Treatment toEntity() {
    return Treatment(
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
      treatmentHerbs:
          treatmentHerbs
              .map((th) => th.toEntity())
              .toList(),
    );
  }

  // ==========================================================
  // ENTITY → MODEL
  // ==========================================================
  factory TreatmentModel.fromEntity(Treatment treatment) {
    return TreatmentModel(
      id: treatment.id,
      conditionId: treatment.conditionId,
      name: treatment.name,
      methodOfUse: treatment.methodOfUse,
      preparation: treatment.preparation,
      dosageInfants: treatment.dosageInfants,
      dosageAdults: treatment.dosageAdults,
      duration: treatment.duration,
      frequency: treatment.frequency,
      notes: treatment.notes,
      precautions: treatment.precautions,
      sideEffects: treatment.sideEffects,
      disclaimer: treatment.disclaimer,
      isApproved: treatment.isApproved,
      approvedBy: treatment.approvedBy,
      approvedAt: treatment.approvedAt,
      moderationComments: treatment.moderationComments,
      rejectedAt: treatment.rejectedAt,
      rejectedBy: treatment.rejectedBy,
      createdAt: treatment.createdAt,
      updatedAt: treatment.updatedAt,
      treatmentHerbs:
          treatment.treatmentHerbs
              .map((th) => TreatmentHerbModel.fromEntity(th))
              .toList(),
    );
  }
}

// ============================================================
// TREATMENT HERB MODEL
// ============================================================
class TreatmentHerbModel {
  final String id;
  final String treatmentId;
  final String herbId;
  final bool isMain;
  final String? quantity;
  final String? unit;
  final String? preparation;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Nested herb data from Supabase join.
  final HerbModel? herb;

  TreatmentHerbModel({
    required this.id,
    required this.treatmentId,
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
  factory TreatmentHerbModel.fromJson(Map<String, dynamic> json) {
    return TreatmentHerbModel(
      id: json['id'] as String,
      treatmentId: json['treatment_id'] as String,
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
      'treatment_id': treatmentId,
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
  TreatmentHerb toEntity() {
    return TreatmentHerb(
      id: id,
      treatmentId: treatmentId,
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
  factory TreatmentHerbModel.fromEntity(TreatmentHerb treatmentHerb) {
    return TreatmentHerbModel(
      id: treatmentHerb.id,
      treatmentId: treatmentHerb.treatmentId,
      herbId: treatmentHerb.herbId,
      isMain: treatmentHerb.isMain,
      quantity: treatmentHerb.quantity,
      unit: treatmentHerb.unit,
      preparation: treatmentHerb.preparation,
    );
  }
}
