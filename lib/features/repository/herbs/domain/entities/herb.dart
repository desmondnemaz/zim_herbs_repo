class Herb {
  final String id;
  final String nameEn;
  final String? nameSn;
  final String? nameNd;
  final String? description;

  const Herb({
    required this.id,
    required this.nameEn,
    this.nameSn,
    this.nameNd,
    this.description,
  });
}