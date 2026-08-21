/// Domain Entities for the Herb Feature.
///
/// Pure business entities independent of any database or framework.
library;

class HerbImage {
  final String id;
  final String herbId;
  final String imageUrl;
  final String? description;
  final int orderIndex;

  const HerbImage({
    required this.id,
    required this.herbId,
    required this.imageUrl,
    this.description,
    this.orderIndex = 0,
  });
}

class Herb {
  final String id;
  final String nameEn;
  final String? nameSn;
  final String? nameNd;
  final String? description;
  final List<HerbImage> images;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Herb({
    required this.id,
    required this.nameEn,
    this.nameSn,
    this.nameNd,
    this.description,
    this.images = const [],
    this.createdAt,
    this.updatedAt,
  });

  /// URL of the primary/first image (if available).
  String? get primaryImageUrl =>
      images.isNotEmpty ? images.first.imageUrl : null;

  /// User-facing display name.
  String get displayName => nameEn;
}
