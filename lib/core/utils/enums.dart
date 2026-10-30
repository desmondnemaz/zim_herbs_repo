// lib/utils/enums.dart

import 'package:flutter/material.dart';

/// Body systems used by conditions
/// Must stay in sync with Supabase enum values
enum BodySystem {
  circulatory,
  respiratory,
  digestive,
  nervous,
  musculoskeletal,
  immuneEndocrine,
}

/// Convert string from Supabase (snake_case) → Dart enum
BodySystem bodySystemFromString(String value) {
  final normalized = value.toLowerCase().trim();

  switch (normalized) {
    case 'circulatory':
      return BodySystem.circulatory;
    case 'respiratory':
      return BodySystem.respiratory;
    case 'digestive':
      return BodySystem.digestive;
    case 'nervous':
      return BodySystem.nervous;
    case 'musculoskeletal':
      return BodySystem.musculoskeletal;
    case 'immune_endocrine':
      return BodySystem.immuneEndocrine;
    default:
      return BodySystem.circulatory; // safe fallback
  }
}

/// Convert Dart enum → Supabase enum string
String bodySystemToString(BodySystem system) {
  switch (system) {
    case BodySystem.circulatory:
      return 'circulatory';
    case BodySystem.respiratory:
      return 'respiratory';
    case BodySystem.digestive:
      return 'digestive';
    case BodySystem.nervous:
      return 'nervous';
    case BodySystem.musculoskeletal:
      return 'musculoskeletal';
    case BodySystem.immuneEndocrine:
      return 'immune_endocrine';
  }
}

/// Friendly label for UI display
String bodySystemLabel(BodySystem system) {
  switch (system) {
    case BodySystem.circulatory:
      return 'Circulatory';
    case BodySystem.respiratory:
      return 'Respiratory';
    case BodySystem.digestive:
      return 'Digestive';
    case BodySystem.nervous:
      return 'Nervous';
    case BodySystem.musculoskeletal:
      return 'Musculoskeletal';
    case BodySystem.immuneEndocrine:
      return 'Immune / Endocrine';
  }
}

/// Color used consistently across UI
Color getBodySystemColor(BodySystem system) {
  switch (system) {
    case BodySystem.circulatory:
      return Colors.red;
    case BodySystem.respiratory:
      return Colors.blue;
    case BodySystem.digestive:
      return Colors.orange;
    case BodySystem.nervous:
      return Colors.purple;
    case BodySystem.musculoskeletal:
      return Colors.green;
    case BodySystem.immuneEndocrine:
      return Colors.teal;
  }
}

/// Icon used consistently across UI
String getBodySystemSvg(BodySystem system) {
  switch (system) {
    case BodySystem.circulatory:
      return 'assets/icons/body_systems/cardiology.svg';
    case BodySystem.respiratory:
      return 'assets/icons/body_systems/pulmonology.svg';
    case BodySystem.digestive:
      return 'assets/icons/body_systems/gastroenterology.svg';
    case BodySystem.nervous:
      return 'assets/icons/body_systems/neurology.svg';
    case BodySystem.musculoskeletal:
      return 'assets/icons/unknown.svg'; // Using unknown for now
    case BodySystem.immuneEndocrine:
      return 'assets/icons/body_systems/endocrinology.svg';
  }
}

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
