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
