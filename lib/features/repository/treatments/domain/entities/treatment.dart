/// Domain Entities for the Treatment Feature.
///
/// Pure business entities independent of any database or framework.
library;

import 'package:zim_herbs_repo/core/utils/enums.dart';

/// Represents a single herb used within a treatment,
/// including its role, quantity, and preparation info.
class TreatmentHerb {
  final String id;
  final String treatmentId;
  final String herbId;
  final bool isMain;
  final String? quantity;
  final String? unit;
  final String? preparation;

  /// Denormalised herb name for display convenience.
  final String? herbName;

  /// Denormalised herb image URL for display convenience.
  final String? herbImageUrl;

  const TreatmentHerb({
    required this.id,
    required this.treatmentId,
    required this.herbId,
    this.isMain = false,
    this.quantity,
    this.unit,
    this.preparation,
    this.herbName,
    this.herbImageUrl,
  });
}

/// Pure domain entity representing a Treatment.
///
/// Independent of database or serialisation concerns.
class Treatment {
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

  // Moderation
  final bool isApproved;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? moderationComments;
  final DateTime? rejectedAt;
  final String? rejectedBy;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Denormalised condition name for display convenience.
  final String? conditionName;

  /// Denormalised condition body system for display/icon convenience.
  final BodySystem? conditionBodySystem;

  /// Herbs used in this treatment (domain sub-entities).
  final List<TreatmentHerb> treatmentHerbs;

  const Treatment({
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
    this.conditionName,
    this.conditionBodySystem,
    this.treatmentHerbs = const [],
  });

  /// User-facing display name generated from the herbs in this treatment.
  ///
  /// 1 herb  → "Aloe vera"
  /// 2 herbs → "Aloe vera + Lippia javanica"
  /// 3 herbs → "Aloe vera + Lippia javanica + Moringa"
  ///
  /// Falls back to the stored [name] if no herb names are available yet
  /// (e.g. when the treatment_herbs join hasn't been loaded).
  String get displayName {
    final herbNames = treatmentHerbs
        .map((th) => th.herbName)
        .whereType<String>()
        .where((n) => n.isNotEmpty)
        .toList();

    if (herbNames.isEmpty) return name;
    return herbNames.join(' + ');
  }
}
