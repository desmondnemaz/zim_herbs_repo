import '../models/product_model.dart';

class StoreRepository {
  final List<ProductModel> _allProducts = [
    ProductModel(
      id: '1',
      name: 'Moringa Powder',
      price: '\$12.00',
      imageUrl:
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSsJYqhRp6x7cVhyhEkQsdsaHlGbpK3LomYuQ&s',
      description:
          'Our Moringa Powder is sourced from organic farms in Bindura. Highly nutrient-dense and perfect for smoothies.',
      category: 'Dried Herbs',
      supplierName: 'ZimNatural Farms',
      supplierLocation: 'Bindura, Zimbabwe',
    ),
    ProductModel(
      id: '2',
      name: 'Baobab Oil',
      price: '\$25.00',
      imageUrl:
          'https://theagrob.com/wp-content/uploads/2025/05/Baobab-Carrier-Oil-510x510.jpg.webp',
      description:
          'Cold-pressed Baobab oil from Chiredzi. Known for its skin-rejuvenating properties.',
      category: 'Essential Oils',
      supplierName: 'Baobab Collective',
      supplierLocation: 'Chiredzi, Zimbabwe',
    ),
    ProductModel(
      id: '3',
      name: 'Dried Hibiscus',
      price: '\$8.50',
      imageUrl:
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ8laQznTksoYDjSZcsMDRcfFEXZfwEDSdzOw&s',
      description:
          'Standard grade dried hibiscus flowers from the Highlands. Great for tea.',
      category: 'Dried Herbs',
      supplierName: 'Highlands Herbalist',
      supplierLocation: 'Nyanga, Zimbabwe',
    ),
    ProductModel(
      id: '4',
      name: 'Zumbani Tea',
      price: '\$5.99',
      imageUrl:
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRRcLSOyrO5ufTfLMe_PsNBPOH6ZAN59nUQ6A&s',
      description: 'Traditional Zimbabwe lemon bush tea. Sourced from Murewa.',
      category: 'Tinctures',
      supplierName: 'Murewa Organics',
      supplierLocation: 'Murewa, Zimbabwe',
    ),
    ProductModel(
      id: '5',
      name: 'Aloe Vera Gel',
      price: '\$14.00',
      imageUrl:
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSyffc9TqY0BOI3mcrnOxcreBTSxRXgitJgrg&s',
      description:
          'Pure Aloe Vera gel extracted using traditional methods in Bulawayo.',
      category: 'Essential Oils',
      supplierName: 'Sunshine Herbs',
      supplierLocation: 'Bulawayo, Zimbabwe',
    ),
    ProductModel(
      id: '6',
      name: 'Devil\'s Claw',
      price: '\$18.50',
      imageUrl:
          'https://image.made-in-china.com/2f0j00bvBhICecAzUq/Anti-Inflammatory-Devil-S-Claw-Extract-3-5-10-Harpagosides-Harpagophytum-Procumbens-Pharmaceutical-Grade.webp',
      description:
          'Powerful traditional remedy for inflammation. Harvested in Hwange.',
      category: 'Supplements',
      supplierName: 'Kalahari Roots',
      supplierLocation: 'Hwange, Zimbabwe',
    ),
  ];

  Future<List<ProductModel>> getProducts({String? category}) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    if (category == null || category == 'All') {
      return _allProducts;
    }
    return _allProducts.where((p) => p.category == category).toList();
  }

  Future<ProductModel?> getProductById(String id) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      return _allProducts.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
