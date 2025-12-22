import 'package:zim_herbs_repo/features/conditions/data/repository/model.dart';
import 'package:zim_herbs_repo/features/herbs/data/models.dart';

class TreatmentModel {
  final String id;
  // herbId removed as per new schema (1:N via junction table)
  final String conditionId;
  final String name;
  final String
  methodOfUse; // Made required/non-nullable based on "text not null"
  final String preparation; // Made required/non-nullable

  // New Dosages
  final String? dosageInfants;
  final String? dosageAdults;

  // Other new fields
  final String? duration;
  final String? frequency;
  final String? notes; // notes text null

  final String? precautions;
  final String? sideEffects;
  final String? disclaimer;

  // Approval / Moderation
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

  factory TreatmentModel.fromJson(Map<String, dynamic> json) {
    return TreatmentModel(
      id: json['id'] as String,
      conditionId: json['condition_id'] as String,
      name:
          json['name'] as String? ??
          'Unnamed Treatment', // Fallback if null (though schema says not null)
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
                (e) => TreatmentHerbModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

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
      'approved_by':
          approvedBy, // Optional: might not want to send this on regular update
      'moderation_comments': moderationComments,
    };
  }
}

class TreatmentHerbModel {
  final String id;
  final String treatmentId;
  final String herbId;
  final bool isMain;
  final String? quantity;
  final String? unit;
  final String? preparation; // Added preparation to match schema
  final DateTime? createdAt;
  final DateTime? updatedAt;
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
}
