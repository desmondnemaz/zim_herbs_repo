import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/models/cart_item_model.dart';
import '../data/models/product_model.dart';
import 'cart_state.dart';

class CartCubit extends Cubit<CartState> {
  CartCubit() : super(CartState.initial());

  void addToCart(ProductModel product, int quantity) {
    final List<CartItemModel> currentItems = List.from(state.items);
    final int existingIndex = currentItems.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (existingIndex != -1) {
      currentItems[existingIndex] = currentItems[existingIndex].copyWith(
        quantity: currentItems[existingIndex].quantity + quantity,
      );
    } else {
      currentItems.add(CartItemModel(product: product, quantity: quantity));
    }

    emit(
      CartState(items: currentItems, totalPrice: _calculateTotal(currentItems)),
    );
  }

  void removeFromCart(String productId) {
    final List<CartItemModel> currentItems = List.from(state.items);
    currentItems.removeWhere((item) => item.product.id == productId);

    emit(
      CartState(items: currentItems, totalPrice: _calculateTotal(currentItems)),
    );
  }

  void clearCart() {
    emit(CartState.initial());
  }

  double _calculateTotal(List<CartItemModel> items) {
    return items.fold(0.0, (total, item) {
      final price =
          double.tryParse(item.product.price.replaceAll('\$', '')) ?? 0.0;
      return total + (price * item.quantity);
    });
  }
}
