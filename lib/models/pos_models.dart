// Purpose: Data models for POS System (categories, products, and order items).
// Keeping models separate from UI ensures clean architecture and reusability.

import 'package:flutter/foundation.dart';

/// Category model representing a product grouping
class Category {
  final String id;
  final String name;

  const Category({required this.id, required this.name});
}

/// Product model for items that can be sold/added to cart
class Product {
  final String id;
  final String name;
  final double price;
  final String categoryId;
  final String? imageUrl; // optional for web/mobile

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.categoryId,
    this.imageUrl,
  });
}

/// Order item represents a product in the cart with a quantity
class OrderItem {
  final Product product;
  int quantity;

  OrderItem({required this.product, this.quantity = 1}) : assert(quantity > 0);

  double get subtotal => product.price * quantity;
}

/// Helper to compute summaries for a list of order items
class OrderSummaryHelper {
  static double total(List<OrderItem> items) {
    return items.fold(0.0, (sum, it) => sum + it.subtotal);
  }

  static int itemCount(List<OrderItem> items) {
    return items.fold(0, (sum, it) => sum + it.quantity);
  }
}