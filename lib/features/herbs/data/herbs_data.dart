class Herb {
  final String name;
  final String imagePath;
  final String description;

  Herb({
    required this.name,
    required this.imagePath,
    required this.description,
  });
}

List<Herb> herbs = [
  Herb(name: "Zumbani", imagePath: "assets/images/zumbani.png", description: "Boosts immunity"),
  Herb(name: "Ginger", imagePath: "assets/images/ginger.png", description: "Helps digestion"),
];
