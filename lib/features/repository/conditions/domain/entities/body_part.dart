import 'package:equatable/equatable.dart';

/// Pure domain entity representing a Body Part.
/// Maps to the `body_parts` table in Supabase.
class BodyPart extends Equatable {
  final String id;
  final String? code;
  final String nameEn;
  final String? nameSn;
  final String? nameNd;
  final String? description;
  final String? iconUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BodyPart({
    required this.id,
    this.code,
    required this.nameEn,
    this.nameSn,
    this.nameNd,
    this.description,
    this.iconUrl,
    this.createdAt,
    this.updatedAt,
  });

  /// Primary display name (English)
  String get displayName => nameEn;

  /// Display name with Shona / Ndebele translations if present
  String get localizedName {
    final extras = <String>[
      if (nameSn != null && nameSn!.trim().isNotEmpty) nameSn!.trim(),
      if (nameNd != null && nameNd!.trim().isNotEmpty) nameNd!.trim(),
    ];
    if (extras.isNotEmpty) {
      return '$nameEn (${extras.join(', ')})';
    }
    return nameEn;
  }

  @override
  List<Object?> get props => [
        id,
        code,
        nameEn,
        nameSn,
        nameNd,
        description,
        iconUrl,
        createdAt,
        updatedAt,
      ];
}
