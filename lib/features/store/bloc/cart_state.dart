import '../data/models/cart_item_model.dart';

class CartState {
  final List<CartItemModel> items;
  final double totalPrice;

  CartState({required this.items, required this.totalPrice});

  CartState.initial() : items = [], totalPrice = 0.0;
}
