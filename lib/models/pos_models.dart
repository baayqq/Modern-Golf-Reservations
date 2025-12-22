import 'package:flutter/foundation.dart';

class Category {
  final String id;
  final String name;

  const Category({required this.id, required this.name});
}

class Product {
  final String id;
  final String name;
  final double price;
  final String categoryId;
  final String? imageUrl;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.categoryId,
    this.imageUrl,
  });
}

class OrderItem {
  final Product product;
  int quantity;

  OrderItem({required this.product, this.quantity = 1}) : assert(quantity > 0);

  double get subtotal => product.price * quantity;
}

class OrderSummaryHelper {
  static double total(List<OrderItem> items) {
    return items.fold(0.0, (sum, it) => sum + it.subtotal);
  }

  static int itemCount(List<OrderItem> items) {
    return items.fold(0, (sum, it) => sum + it.quantity);
  }
}