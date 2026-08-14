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
/// HerbModel  ← this file
///    ↓
/// Herb Entity
///    ↓
/// Domain / Cubit
library;

import 'package:zim_herbs_repo/features/repository/treatments/data/treatment_models.dart';

/// Import the DOMAIN entity.
///
/// IMPORTANT:
/// HerbModel belongs to DATA.
/// Herb belongs to DOMAIN.
///
/// We use this entity so that the domain layer
/// does not have to depend directly on Supabase models.
import '../../domain/entities/herb.dart';


/// ============================================================
/// HERB MODEL
/// ============================================================
///
/// HerbModel represents the `herbs` table in Supabase.
///
/// It is responsible for:
/// - Reading Supabase JSON
/// - Converting JSON → HerbModel
/// - Converting HerbModel → JSON
/// - Holding database-related data such as images and treatments
///
/// This is a DATA-layer class.
class HerbModel {

  /// The unique ID of the herb.
  final String id;

  /// English name of the herb.
  final String nameEn;

  /// Optional Shona name.
  final String? nameSn;

  /// Optional Ndebele name.
  final String? nameNd;

  /// Optional description of the herb.
  final String? description;

  /// When the herb was created in Supabase.
  final DateTime? createdAt;

  /// When the herb was last updated.
  final DateTime? updatedAt;

  /// Images belonging to this herb.
  ///
  /// We use another model:
  /// HerbImageModel
  final List<HerbImageModel> images;

  /// Treatments associated with this herb.
  ///
  /// TreatmentModel belongs to the DATA layer
  /// because it represents database data.
  final List<TreatmentModel> treatments;


  /// Constructor for creating a HerbModel manually.
  ///
  /// `required` means these values must be provided.
  ///
  /// Images and treatments default to empty lists
  /// when no values are provided.
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


  /// ==========================================================
  /// MODEL → ENTITY
  /// ==========================================================
  ///
  /// This method converts a DATA object (HerbModel)
  /// into a DOMAIN object (Herb).
  ///
  /// Why do we need this?
  ///
  /// Our Domain layer should not care whether our data
  /// comes from:
  ///
  /// - Supabase
  /// - Firebase
  /// - REST API
  /// - Local database
  ///
  /// The Domain layer works with the `Herb` entity.
  ///
  /// Therefore:
  ///
  /// HerbModel
  ///     ↓
  /// toEntity()
  ///     ↓
  /// Herb
  Herb toEntity() {
    return Herb(
      id: id,
      nameEn: nameEn,
      nameSn: nameSn,
      nameNd: nameNd,
      description: description,
    );
  }


  /// ==========================================================
  /// ENTITY → MODEL
  /// ==========================================================
  ///
  /// This is the opposite of `toEntity()`.
  ///
  /// It converts a DOMAIN entity into a DATA model.
  ///
  /// Example:
  ///
  /// Herb
  ///   ↓
  /// fromEntity()
  ///   ↓
  /// HerbModel
  ///
  /// This becomes useful when we want to send domain data
  /// back to the database.
  factory HerbModel.fromEntity(Herb herb) {
    return HerbModel(
      id: herb.id,
      nameEn: herb.nameEn,
      nameSn: herb.nameSn,
      nameNd: herb.nameNd,
      description: herb.description,
    );
  }


  /// ==========================================================
  /// JSON → MODEL
  /// ==========================================================
  ///
  /// Supabase returns data as JSON-like Maps.
  ///
  /// Example:
  ///
  /// {
  ///   "id": "123",
  ///   "name_en": "Moringa",
  ///   "name_sn": "Mufushwa"
  /// }
  ///
  /// `fromJson()` converts that database response
  /// into a Dart HerbModel object.
  ///
  /// This is one of the most important methods
  /// in the DATA layer.
  factory HerbModel.fromJson(Map<String, dynamic> json) {

    /// Extract herb images from the Supabase response.
    ///
    /// If `herb_images` does not exist,
    /// use an empty list instead.
    final images =
        (json['herb_images'] as List<dynamic>?)
            ?.map(
              (e) => HerbImageModel.fromJson(
                e as Map<String, dynamic>,
              ),
            )
            .toList() ??
        [];

    /// Sort images according to their order index.
    ///
    /// This allows us to determine which image
    /// should appear first.
    images.sort(
      (a, b) => a.orderIndex.compareTo(b.orderIndex),
    );


    /// Create and return the HerbModel.
    return HerbModel(
      /// Convert the JSON `id` into a String.
      id: json['id'] as String,

      /// Convert `name_en` into a String.
      nameEn: json['name_en'] as String,

      /// Shona name can be null.
      nameSn: json['name_sn'] as String?,

      /// Ndebele name can be null.
      nameNd: json['name_nd'] as String?,

      /// Description can also be null.
      description: json['description'] as String?,

      /// Convert the Supabase timestamp into DateTime.
      ///
      /// If there is no timestamp, keep it null.
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(
                  json['created_at'] as String,
                )
              : null,

      /// Same process for updated_at.
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(
                  json['updated_at'] as String,
                )
              : null,

      /// Attach the images we extracted above.
      images: images,

      /// Extract treatment information.
      ///
      /// Supabase returns:
      ///
      /// treatment_herbs
      ///       ↓
      /// treatments
      ///
      /// Therefore we go inside the relationship
      /// to get the actual treatment object.
      treatments:
          (json['treatment_herbs'] as List<dynamic>?)
              ?.map((e) {

                /// Get the nested treatment object.
                final treatmentJson =
                    e['treatments']
                        as Map<String, dynamic>?;

                /// If there is no treatment,
                /// return null.
                if (treatmentJson == null) {
                  return null;
                }

                /// Convert the JSON treatment into
                /// a TreatmentModel.
                return TreatmentModel.fromJson(
                  treatmentJson,
                );
              })

              /// Remove null values from the list.
              .whereType<TreatmentModel>()

              /// Convert the result into a List.
              .toList() ??
          [],
    );
  }


  /// ==========================================================
  /// MODEL → JSON
  /// ==========================================================
  ///
  /// Converts HerbModel back into a Map.
  ///
  /// This is useful when inserting or updating
  /// records in Supabase.
  ///
  /// Example:
  ///
  /// HerbModel
  ///    ↓
  /// toJson()
  ///    ↓
  /// A Map containing String keys and dynamic values.
  ///    ↓
  /// Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_en': nameEn,
      'name_sn': nameSn,
      'name_nd': nameNd,
      'description': description,
    };
  }


  /// ==========================================================
  /// PRIMARY IMAGE
  /// ==========================================================
  ///
  /// Returns the first/primary image of the herb.
  ///
  /// If there are no images,
  /// return null.
  String? get primaryImageUrl {

    /// No images = no primary image.
    if (images.isEmpty) {
      return null;
    }

    /// Create a copy of the images list
    /// so that we don't modify the original list.
    final sorted = List<HerbImageModel>.from(images)

      /// Sort images using their order index.
      ..sort(
        (a, b) =>
            a.orderIndex.compareTo(b.orderIndex),
      );

    /// Return the URL of the first image.
    return sorted.first.imageUrl;
  }


  /// ==========================================================
  /// DISPLAY NAME
  /// ==========================================================
  ///
  /// A convenient getter used by the UI.
  ///
  /// For now we simply display the English name.
  String get displayName => nameEn;
}


/// ============================================================
/// HERB IMAGE MODEL
/// ============================================================
///
/// Represents a record from the `herb_images` table.
///
/// This is also part of the DATA layer.
class HerbImageModel {

  /// Unique ID of the image record.
  final String id;

  /// ID of the herb this image belongs to.
  final String herbId;

  /// URL of the image.
  final String imageUrl;

  /// Optional image description.
  final String? description;

  /// Determines the order in which images appear.
  final int orderIndex;


  /// Constructor.
  HerbImageModel({
    required this.id,
    required this.herbId,
    required this.imageUrl,
    this.description,
    this.orderIndex = 0,
  });


  /// ==========================================================
  /// JSON → HERB IMAGE MODEL
  /// ==========================================================
  ///
  /// Converts Supabase JSON into HerbImageModel.
  factory HerbImageModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return HerbImageModel(
      id: json['id'] as String,
      herbId: json['herb_id'] as String,
      imageUrl: json['image_url'] as String,
      description: json['description'] as String?,
      orderIndex:
          json['order_index'] as int? ?? 0,
    );
  }


  /// ==========================================================
  /// HERB IMAGE MODEL → JSON
  /// ==========================================================
  ///
  /// Converts the Dart object into a Map
  /// that can be sent to Supabase.
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