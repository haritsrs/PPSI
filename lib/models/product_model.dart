class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final int stock;
  final int minStock;
  final String supplier;
  final String category;
  final String barcode;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.minStock,
    required this.supplier,
    required this.category,
    required this.barcode,
    required this.createdAt,
    required this.updatedAt,
    this.imageUrl = '',
  });

  bool get isLowStock => stock <= minStock;
  bool get isOutOfStock => stock == 0;
  
  double get stockPercentage => stock / (minStock * 3); // Assuming 3x minStock is full stock
  
  String get stockStatus {
    if (isOutOfStock) return 'Habis';
    if (isLowStock) return 'Hampir Habis';
    return 'Tersedia';
  }
}
