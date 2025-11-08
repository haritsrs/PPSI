import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Products operations
  DatabaseReference get productsRef => _database.child('products');
  
  // Stream of all products
  Stream<List<Map<String, dynamic>>> getProductsStream() {
    return productsRef.onValue.map((event) {
      if (event.snapshot.value == null) {
        return <Map<String, dynamic>>[];
      }
      
      final Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
      final List<Map<String, dynamic>> products = [];
      
      data.forEach((key, value) {
        if (value is Map) {
          products.add({
            'id': key,
            ...Map<String, dynamic>.from(value),
          });
        }
      });
      
      return products;
    });
  }

  // Get all products once
  Future<List<Map<String, dynamic>>> getProducts() async {
    final snapshot = await productsRef.get();
    if (snapshot.value == null) {
      return [];
    }
    
    final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
    final List<Map<String, dynamic>> products = [];
    
    data.forEach((key, value) {
      if (value is Map) {
        products.add({
          'id': key,
          ...Map<String, dynamic>.from(value),
        });
      }
    });
    
    return products;
  }

  // Add a new product
  Future<String> addProduct(Map<String, dynamic> productData) async {
    final newProductRef = productsRef.push();
    await newProductRef.set({
      ...productData,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
      'createdBy': currentUserId ?? 'unknown',
    });
    return newProductRef.key!;
  }

  // Update a product
  Future<void> updateProduct(String productId, Map<String, dynamic> productData) async {
    await productsRef.child(productId).update({
      ...productData,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // Delete a product
  Future<void> deleteProduct(String productId) async {
    await productsRef.child(productId).remove();
  }

  // Update product stock
  Future<void> updateProductStock(String productId, int newStock) async {
    await productsRef.child(productId).update({
      'stock': newStock,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // Decrement product stock (for sales)
  Future<void> decrementProductStock(String productId, int quantity) async {
    final productRef = productsRef.child(productId);
    final snapshot = await productRef.child('stock').get();
    
    if (snapshot.exists) {
      final currentStock = (snapshot.value as num).toInt();
      final newStock = (currentStock - quantity).clamp(0, double.infinity).toInt();
      
      await productRef.update({
        'stock': newStock,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }
  }

  // Transactions operations
  DatabaseReference get transactionsRef => _database.child('transactions');
  
  // Add a new transaction
  Future<String> addTransaction({
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double tax,
    required double total,
    required String paymentMethod,
    double? cashAmount,
    double? change,
  }) async {
    final newTransactionRef = transactionsRef.push();
    final transactionId = newTransactionRef.key!;
    
    final transactionData = {
      'id': transactionId,
      'items': items,
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'paymentMethod': paymentMethod,
      'cashAmount': cashAmount,
      'change': change,
      'createdAt': DateTime.now().toIso8601String(),
      'createdBy': currentUserId ?? 'unknown',
    };
    
    await newTransactionRef.set(transactionData);
    
    // Update stock for each item
    for (var item in items) {
      final productId = item['productId'] as String;
      final quantity = item['quantity'] as int;
      await decrementProductStock(productId, quantity);
    }
    
    return transactionId;
  }

  // Get transactions stream
  Stream<List<Map<String, dynamic>>> getTransactionsStream() {
    return transactionsRef.orderByChild('createdAt').onValue.map((event) {
      if (event.snapshot.value == null) {
        return <Map<String, dynamic>>[];
      }
      
      final Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
      final List<Map<String, dynamic>> transactions = [];
      
      data.forEach((key, value) {
        if (value is Map) {
          transactions.add({
            'id': key,
            ...Map<String, dynamic>.from(value),
          });
        }
      });
      
      return transactions.reversed.toList(); // Most recent first
    });
  }

  // Get categories from products
  Future<List<String>> getCategories() async {
    final products = await getProducts();
    final categories = <String>{'Semua'};
    
    for (var product in products) {
      final category = product['category'] as String?;
      if (category != null && category.isNotEmpty) {
        categories.add(category);
      }
    }
    
    return categories.toList()..sort();
  }
}

