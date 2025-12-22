/// Models for Supabase database tables
/// Matches the schema: Herbs, Conditions, Treatments, Herb Images

library;

import 'package:zim_herbs_repo/features/treatments/data/treatment_models.dart';

class HerbModel {
  final String id;
  final String nameEn;
  final String? nameSn; // Shona name
  final String? nameNd; // Ndebele name
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<HerbImageModel> images;
  final List<TreatmentModel> treatments;

  HerbModel({
    required this.id,
    required this.nameEn,
    this.nameSn,
    this.nameNd,
    this.description,
    this.createdAt,
    this.updatedAt,
    this.images = const [],
    this.treatments = const [],
  });

  factory HerbModel.fromJson(Map<String, dynamic> json) {
    return HerbModel(
      id: json['id'] as String,
      nameEn: json['name_en'] as String,
      nameSn: json['name_sn'] as String?,
      nameNd: json['name_nd'] as String?,
      description: json['description'] as String?,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : null,
      images:
          (json['herb_images'] as List<dynamic>?)?.map((e) {
            return HerbImageModel.fromJson(e as Map<String, dynamic>);
          }).toList() ??
          [],
      treatments:
          (json['treatment_herbs'] as List<dynamic>?)
              ?.map((e) {
                // The treatment object is nested inside the treatment_herb record
                final treatmentJson = e['treatments'] as Map<String, dynamic>?;
                if (treatmentJson == null) return null;
                return TreatmentModel.fromJson(treatmentJson);
              })
              .whereType<TreatmentModel>()
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_en': nameEn,
      'name_sn': nameSn,
      'name_nd': nameNd,
      'description': description,
    };
  }

  /// Returns the primary image URL or null if no images
  String? get primaryImageUrl {
    if (images.isEmpty) return null;
    final sorted = List<HerbImageModel>.from(images)
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return sorted.first.imageUrl;
  }

  /// Returns display name with fallback
  String get displayName => nameEn;
}

class HerbImageModel {
  final String id;
  final String herbId;
  final String imageUrl;
  final String? description;
  final int orderIndex;

  HerbImageModel({
    required this.id,
    required this.herbId,
    required this.imageUrl,
    this.description,
    this.orderIndex = 0,
  });

  factory HerbImageModel.fromJson(Map<String, dynamic> json) {
    return HerbImageModel(
      id: json['id'] as String,
      herbId: json['herb_id'] as String,
      imageUrl: json['image_url'] as String,
      description: json['description'] as String?,
      orderIndex: json['order_index'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'herb_id': herbId,
      'image_url': imageUrl,
      'description': description,
      'order_index': orderIndex,
    };
  }
}
