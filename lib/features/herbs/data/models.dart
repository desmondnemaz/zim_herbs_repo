/// Models for Supabase database tables
/// Matches the schema: Herbs, Conditions, Treatments, Herb Images

library;

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
          (json['treatments'] as List<dynamic>?)
              ?.map((e) => TreatmentModel.fromJson(e as Map<String, dynamic>))
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

class ConditionModel {
  final String id;
  final String name;
  final String? bodySystem;
  final String? description;
  final String? symptoms;
  final String? precautions;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ConditionModel({
    required this.id,
    required this.name,
    this.bodySystem,
    this.description,
    this.symptoms,
    this.precautions,
    this.createdAt,
    this.updatedAt,
  });

  factory ConditionModel.fromJson(Map<String, dynamic> json) {
    return ConditionModel(
      id: json['id'] as String,
      name: json['name'] as String,
      bodySystem: json['body_system'] as String?,
      description: json['description'] as String?,
      symptoms: json['symptoms'] as String?,
      precautions: json['precautions'] as String?,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'body_system': bodySystem,
      'description': description,
      'symptoms': symptoms,
      'precautions': precautions,
    };
  }
}

class TreatmentModel {
  final String id;
  final String herbId;
  final String conditionId;
  final String? dosage;
  final String? preparation;
  final String? methodOfUse;
  final String? precautions;
  final String? sideEffects;
  final String? disclaimer;
  final DateTime? createdAt;
  final ConditionModel? condition;

  TreatmentModel({
    required this.id,
    required this.herbId,
    required this.conditionId,
    this.dosage,
    this.preparation,
    this.methodOfUse,
    this.precautions,
    this.sideEffects,
    this.disclaimer,
    this.createdAt,
    this.condition,
  });

  factory TreatmentModel.fromJson(Map<String, dynamic> json) {
    return TreatmentModel(
      id: json['id'] as String,
      herbId: json['herb_id'] as String,
      conditionId: json['condition_id'] as String,
      dosage: json['dosage'] as String?,
      preparation: json['preparation'] as String?,
      methodOfUse: json['method_of_use'] as String?,
      precautions: json['precautions'] as String?,
      sideEffects: json['side_effects'] as String?,
      disclaimer: json['disclaimer'] as String?,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : null,
      condition:
          json['conditions'] != null
              ? ConditionModel.fromJson(
                json['conditions'] as Map<String, dynamic>,
              )
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'herb_id': herbId,
      'condition_id': conditionId,
      'dosage': dosage,
      'preparation': preparation,
      'method_of_use': methodOfUse,
      'precautions': precautions,
      'side_effects': sideEffects,
      'disclaimer': disclaimer,
    };
  }
}
