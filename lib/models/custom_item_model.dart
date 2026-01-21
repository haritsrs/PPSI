/// Model for custom/manual items added to cart
/// These are items not in the product catalog with user-defined name and price
class CustomItem {
  final String id;
  final String name;
  final double price;
  int quantity;

  CustomItem({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
  });

  double get subtotal => price * quantity;

  /// Convert to Firebase-compatible map for transaction storage
  Map<String, dynamic> toFirebase() {
    return {
      'name': name,
      'price': price,
      'quantity': quantity,
      'subtotal': subtotal,
      'isCustom': true,
    };
  }
}

