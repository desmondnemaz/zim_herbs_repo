import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zim_herbs_repo/features/store/data/models/product_model.dart';
import 'package:zim_herbs_repo/features/store/data/repository/store_repository.dart';

abstract class ProductDetailState extends Equatable {
  const ProductDetailState();

  @override
  List<Object?> get props => [];
}

class ProductDetailInitial extends ProductDetailState {}

class ProductDetailLoading extends ProductDetailState {}

class ProductDetailLoaded extends ProductDetailState {
  final ProductModel product;
  final int quantity;

  const ProductDetailLoaded({required this.product, this.quantity = 1});

  @override
  List<Object?> get props => [product, quantity];

  ProductDetailLoaded copyWith({ProductModel? product, int? quantity}) {
    return ProductDetailLoaded(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}

class ProductDetailError extends ProductDetailState {
  final String message;

  const ProductDetailError(this.message);

  @override
  List<Object?> get props => [message];
}

class ProductDetailCubit extends Cubit<ProductDetailState> {
  final StoreRepository _repository;

  ProductDetailCubit(this._repository) : super(ProductDetailInitial());

  Future<void> loadProduct(String id, {ProductModel? initialProduct}) async {
    if (initialProduct != null) {
      emit(ProductDetailLoaded(product: initialProduct));
      return;
    }

    emit(ProductDetailLoading());
    try {
      final product = await _repository.getProductById(id);
      if (product != null) {
        emit(ProductDetailLoaded(product: product));
      } else {
        emit(const ProductDetailError("Product not found"));
      }
    } catch (e) {
      emit(ProductDetailError("Failed to load product: $e"));
    }
  }

  void incrementQuantity() {
    final currentState = state;
    if (currentState is ProductDetailLoaded) {
      emit(currentState.copyWith(quantity: currentState.quantity + 1));
    }
  }

  void decrementQuantity() {
    final currentState = state;
    if (currentState is ProductDetailLoaded && currentState.quantity > 1) {
      emit(currentState.copyWith(quantity: currentState.quantity - 1));
    }
  }
}
