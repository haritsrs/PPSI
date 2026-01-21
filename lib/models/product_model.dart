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
  final String image; // Emoji or image identifier

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
    this.image = '📦',
  });

  factory Product.fromFirebase(Map<String, dynamic> data) {
    return Product(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      stock: (data['stock'] as num?)?.toInt() ?? 0,
      minStock: (data['minStock'] as num?)?.toInt() ?? 10,
      supplier: data['supplier'] as String? ?? '',
      category: data['category'] as String? ?? '',
      barcode: data['barcode'] as String? ?? '',
      image: data['image'] as String? ?? data['imageUrl'] as String? ?? '📦',
      imageUrl: data['imageUrl'] as String? ?? '',
      createdAt: data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? DateTime.tryParse(data['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirebase() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'minStock': minStock,
      'supplier': supplier,
      'category': category,
      'barcode': barcode,
      'image': image,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  bool get isLowStock => stock <= minStock;
  bool get isOutOfStock => stock == 0;
  
  double get stockPercentage => minStock > 0 ? stock / (minStock * 3) : 0.0; // Assuming 3x minStock is full stock
  
  String get stockStatus {
    if (isOutOfStock) return 'Habis';
    if (isLowStock) return 'Hampir Habis';
    return 'Tersedia';
  }
}

