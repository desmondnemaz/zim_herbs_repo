class ProductModel {
  final String id;
  final String name;
  final String price;
  final String imageUrl;
  final String description;
  final String category;
  final String supplierName;
  final String supplierLocation;
  final double rating;
  final int reviewsCount;

  ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.description,
    required this.category,
    required this.supplierName,
    required this.supplierLocation,
    this.rating = 4.8,
    this.reviewsCount = 24,
  });

  // Simplified model for now. Can add copyWith/fromJson later if needed.
}
