import '../data/models/product_model.dart';

abstract class StoreState {}

class StoreInitial extends StoreState {}

class StoreLoading extends StoreState {}

class StoreLoaded extends StoreState {
  final List<ProductModel> products;
  final String? selectedCategory;

  StoreLoaded(this.products, {this.selectedCategory});
}

class StoreError extends StoreState {
  final String message;
  StoreError(this.message);
}
