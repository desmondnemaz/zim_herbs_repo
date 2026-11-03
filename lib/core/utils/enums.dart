// lib/utils/enums.dart

import 'package:flutter/material.dart';

/// Ailment categories used by conditions and remedies.
/// Must stay in sync with Supabase 'ailment_category' enum values.
enum AilmentCategory {
  heartBlood,
  respiratory,
  digestive,
  nervousSystem,
  painJoints,
  immunityHormones,
  reproductiveHealth,
  sexualHealth,
  skinWounds,
  eyesEars,
  dental,
  parasites,
  fever,
  childHealth,
  infections,
  snakebite,
  otherUses;

  /// Backward-compatible aliases for legacy enum constants
  static const AilmentCategory circulatory = AilmentCategory.heartBlood;
  static const AilmentCategory nervous = AilmentCategory.nervousSystem;
  static const AilmentCategory musculoskeletal = AilmentCategory.painJoints;
  static const AilmentCategory immuneEndocrine = AilmentCategory.immunityHormones;
}

/// Convert string from Supabase (snake_case) or legacy names → Dart enum
AilmentCategory ailmentCategoryFromString(String value) {
  final normalized = value.toLowerCase().trim().replaceAll('-', '_').replaceAll(' ', '_');

  switch (normalized) {
    case 'heart_blood':
    case 'heartblood':
    case 'circulatory':
      return AilmentCategory.heartBlood;
    case 'respiratory':
      return AilmentCategory.respiratory;
    case 'digestive':
      return AilmentCategory.digestive;
    case 'nervous_system':
    case 'nervoussystem':
    case 'nervous':
      return AilmentCategory.nervousSystem;
    case 'pain_joints':
    case 'painjoints':
    case 'musculoskeletal':
      return AilmentCategory.painJoints;
    case 'immunity_hormones':
    case 'immunityhormones':
    case 'immune_endocrine':
      return AilmentCategory.immunityHormones;
    case 'reproductive_health':
    case 'reproductivehealth':
      return AilmentCategory.reproductiveHealth;
    case 'sexual_health':
    case 'sexualhealth':
      return AilmentCategory.sexualHealth;
    case 'skin_wounds':
    case 'skinwounds':
      return AilmentCategory.skinWounds;
    case 'eyes_ears':
    case 'eyesears':
      return AilmentCategory.eyesEars;
    case 'dental':
      return AilmentCategory.dental;
    case 'parasites':
      return AilmentCategory.parasites;
    case 'fever':
      return AilmentCategory.fever;
    case 'child_health':
    case 'childhealth':
      return AilmentCategory.childHealth;
    case 'infections':
      return AilmentCategory.infections;
    case 'snakebite':
      return AilmentCategory.snakebite;
    case 'other_uses':
    case 'otheruses':
      return AilmentCategory.otherUses;
    default:
      return AilmentCategory.heartBlood; // safe fallback
  }
}

/// Convert Dart enum → Supabase enum string (snake_case)
String ailmentCategoryToString(AilmentCategory category) {
  switch (category) {
    case AilmentCategory.heartBlood:
      return 'heart_blood';
    case AilmentCategory.respiratory:
      return 'respiratory';
    case AilmentCategory.digestive:
      return 'digestive';
    case AilmentCategory.nervousSystem:
      return 'nervous_system';
    case AilmentCategory.painJoints:
      return 'pain_joints';
    case AilmentCategory.immunityHormones:
      return 'immunity_hormones';
    case AilmentCategory.reproductiveHealth:
      return 'reproductive_health';
    case AilmentCategory.sexualHealth:
      return 'sexual_health';
    case AilmentCategory.skinWounds:
      return 'skin_wounds';
    case AilmentCategory.eyesEars:
      return 'eyes_ears';
    case AilmentCategory.dental:
      return 'dental';
    case AilmentCategory.parasites:
      return 'parasites';
    case AilmentCategory.fever:
      return 'fever';
    case AilmentCategory.childHealth:
      return 'child_health';
    case AilmentCategory.infections:
      return 'infections';
    case AilmentCategory.snakebite:
      return 'snakebite';
    case AilmentCategory.otherUses:
      return 'other_uses';
  }
}

/// Friendly label for UI display
String ailmentCategoryLabel(AilmentCategory category) {
  switch (category) {
    case AilmentCategory.heartBlood:
      return 'Heart & Blood';
    case AilmentCategory.respiratory:
      return 'Respiratory';
    case AilmentCategory.digestive:
      return 'Digestive';
    case AilmentCategory.nervousSystem:
      return 'Nervous System';
    case AilmentCategory.painJoints:
      return 'Pain & Joints';
    case AilmentCategory.immunityHormones:
      return 'Immunity & Hormones';
    case AilmentCategory.reproductiveHealth:
      return 'Reproductive Health';
    case AilmentCategory.sexualHealth:
      return 'Sexual Health';
    case AilmentCategory.skinWounds:
      return 'Skin & Wounds';
    case AilmentCategory.eyesEars:
      return 'Eyes & Ears';
    case AilmentCategory.dental:
      return 'Dental & Oral';
    case AilmentCategory.parasites:
      return 'Parasites';
    case AilmentCategory.fever:
      return 'Fever';
    case AilmentCategory.childHealth:
      return 'Child Health';
    case AilmentCategory.infections:
      return 'Infections';
    case AilmentCategory.snakebite:
      return 'Snakebite';
    case AilmentCategory.otherUses:
      return 'Other Uses';
  }
}

/// Color used consistently across UI
Color getAilmentCategoryColor(AilmentCategory category) {
  switch (category) {
    case AilmentCategory.heartBlood:
      return Colors.red;
    case AilmentCategory.respiratory:
      return Colors.blue;
    case AilmentCategory.digestive:
      return Colors.orange;
    case AilmentCategory.nervousSystem:
      return Colors.purple;
    case AilmentCategory.painJoints:
      return Colors.deepOrange;
    case AilmentCategory.immunityHormones:
      return Colors.teal;
    case AilmentCategory.reproductiveHealth:
      return Colors.pink;
    case AilmentCategory.sexualHealth:
      return Colors.deepPurple;
    case AilmentCategory.skinWounds:
      return Colors.amber.shade800;
    case AilmentCategory.eyesEars:
      return Colors.cyan;
    case AilmentCategory.dental:
      return Colors.lightBlue;
    case AilmentCategory.parasites:
      return Colors.brown;
    case AilmentCategory.fever:
      return Colors.redAccent;
    case AilmentCategory.childHealth:
      return Colors.lightGreen.shade700;
    case AilmentCategory.infections:
      return Colors.indigo;
    case AilmentCategory.snakebite:
      return Colors.green.shade800;
    case AilmentCategory.otherUses:
      return Colors.blueGrey;
  }
}

/// Icon used consistently across UI
String getAilmentCategorySvg(AilmentCategory category) {
  switch (category) {
    case AilmentCategory.heartBlood:
      return 'assets/icons/body_systems/cardiology.svg';
    case AilmentCategory.respiratory:
      return 'assets/icons/body_systems/pulmonology.svg';
    case AilmentCategory.digestive:
      return 'assets/icons/body_systems/gastroenterology.svg';
    case AilmentCategory.nervousSystem:
      return 'assets/icons/body_systems/neurology.svg';
    case AilmentCategory.painJoints:
      return 'assets/icons/unknown.svg';
    case AilmentCategory.immunityHormones:
      return 'assets/icons/body_systems/endocrinology.svg';
    case AilmentCategory.reproductiveHealth:
    case AilmentCategory.sexualHealth:
      return 'assets/icons/body_systems/gynecology.svg';
    case AilmentCategory.eyesEars:
      return 'assets/icons/body_systems/ophthalmology.svg';
    default:
      return 'assets/icons/unknown.svg';
  }
}

// ============================================================================
// BACKWARD COMPATIBILITY ALIASES (BodySystem -> AilmentCategory)
// ============================================================================
typedef BodySystem = AilmentCategory;

BodySystem bodySystemFromString(String value) => ailmentCategoryFromString(value);
String bodySystemToString(BodySystem system) => ailmentCategoryToString(system);
String bodySystemLabel(BodySystem system) => ailmentCategoryLabel(system);
Color getBodySystemColor(BodySystem system) => getAilmentCategoryColor(system);
String getBodySystemSvg(BodySystem system) => getAilmentCategorySvg(system);

/// Represents the 4-stage validation lifecycle + rejection state
enum RecordValidationStatus {
  submitted('submitted', 'Submitted', 1, Color(0xFF64748B), Icons.upload_file_rounded),
  underReview('under_review', 'Under Review', 2, Color(0xFFD97706), Icons.rate_review_outlined),
  validated('validated', 'Validated', 3, Color(0xFF0284C7), Icons.verified_outlined),
  published('published', 'Published', 4, Color(0xFF16A34A), Icons.check_circle_outline_rounded),
  rejected('rejected', 'Rejected', 0, Color(0xFFDC2626), Icons.cancel_outlined);

  final String dbValue;
  final String label;
  final int stepIndex; // 1 to 4, 0 for rejected
  final Color color;
  final IconData icon;

  const RecordValidationStatus(
    this.dbValue,
    this.label,
    this.stepIndex,
    this.color,
    this.icon,
  );

  bool get isTerminal => this == published || this == rejected;
  bool get isApproved => this == published;

  static RecordValidationStatus fromString(String? val, {bool isApproved = false}) {
    if (val == null) {
      return isApproved ? RecordValidationStatus.published : RecordValidationStatus.submitted;
    }
    return RecordValidationStatus.values.firstWhere(
      (e) => e.dbValue == val,
      orElse: () => isApproved ? RecordValidationStatus.published : RecordValidationStatus.submitted,
    );
  }
}
