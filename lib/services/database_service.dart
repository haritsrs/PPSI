import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class DatabaseService {
  static const String databaseURL = 'https://gunadarma-pos-marketplace-default-rtdb.asia-southeast1.firebasedatabase.app/';
  
  late final DatabaseReference _database;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DatabaseService() {
    _database = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: databaseURL,
    ).ref();
  }

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
    String? customerId,
    String? customerName,
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
      if (customerId != null) 'customerId': customerId,
      if (customerName != null) 'customerName': customerName,
    };
    
    await newTransactionRef.set(transactionData);
    
    // Update stock for each item
    for (var item in items) {
      final productId = item['productId'] as String;
      final quantity = item['quantity'] as int;
      await decrementProductStock(productId, quantity);
    }
    
    // Update customer transaction stats if customerId is provided
    if (customerId != null) {
      await updateCustomerTransactionStats(customerId, total);
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

  // Get total store balance from all transactions
  Stream<double> getStoreBalanceStream() {
    return transactionsRef.onValue.map((event) {
      if (event.snapshot.value == null) {
        return 0.0;
      }
      
      final Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
      double totalBalance = 0.0;
      
      data.forEach((key, value) {
        if (value is Map) {
          final total = value['total'];
          if (total != null) {
            totalBalance += (total as num).toDouble();
          }
        }
      });
      
      return totalBalance;
    });
  }

  // Get today's revenue
  Stream<double> getTodayRevenueStream() {
    return transactionsRef.onValue.map((event) {
      if (event.snapshot.value == null) {
        return 0.0;
      }
      
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final tomorrowStart = todayStart.add(const Duration(days: 1));
      
      final Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
      double todayRevenue = 0.0;
      
      data.forEach((key, value) {
        if (value is Map) {
          final createdAt = value['createdAt'];
          if (createdAt != null) {
            try {
              final transactionDate = DateTime.parse(createdAt as String);
              if (transactionDate.isAfter(todayStart.subtract(const Duration(milliseconds: 1))) &&
                  transactionDate.isBefore(tomorrowStart)) {
                final total = value['total'];
                if (total != null) {
                  todayRevenue += (total as num).toDouble();
                }
              }
            } catch (e) {
              // Skip invalid dates
            }
          }
        }
      });
      
      return todayRevenue;
    });
  }

  // Get yesterday's revenue
  Stream<double> getYesterdayRevenueStream() {
    return transactionsRef.onValue.map((event) {
      if (event.snapshot.value == null) {
        return 0.0;
      }
      
      final now = DateTime.now();
      final yesterdayStart = DateTime(now.year, now.month, now.day - 1);
      final todayStart = DateTime(now.year, now.month, now.day);
      
      final Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
      double yesterdayRevenue = 0.0;
      
      data.forEach((key, value) {
        if (value is Map) {
          final createdAt = value['createdAt'];
          if (createdAt != null) {
            try {
              final transactionDate = DateTime.parse(createdAt as String);
              if (transactionDate.isAfter(yesterdayStart.subtract(const Duration(milliseconds: 1))) &&
                  transactionDate.isBefore(todayStart)) {
                final total = value['total'];
                if (total != null) {
                  yesterdayRevenue += (total as num).toDouble();
                }
              }
            } catch (e) {
              // Skip invalid dates
            }
          }
        }
      });
      
      return yesterdayRevenue;
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

  // Notifications operations
  DatabaseReference get notificationsRef {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User must be logged in to access notifications');
    }
    return _database.child('notifications').child(userId);
  }

  // Get notifications stream for current user
  Stream<List<Map<String, dynamic>>> getNotificationsStream() {
    return notificationsRef.orderByChild('createdAt').onValue.map((event) {
      if (event.snapshot.value == null) {
        return <Map<String, dynamic>>[];
      }
      
      final Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
      final List<Map<String, dynamic>> notifications = [];
      
      data.forEach((key, value) {
        if (value is Map) {
          notifications.add({
            'id': key,
            ...Map<String, dynamic>.from(value),
          });
        }
      });
      
      return notifications.reversed.toList(); // Most recent first
    });
  }

  // Get unread notifications count
  Stream<int> getUnreadNotificationsCount() {
    return notificationsRef.orderByChild('isRead').equalTo(false).onValue.map((event) {
      if (event.snapshot.value == null) {
        return 0;
      }
      
      final Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
      int count = 0;
      
      data.forEach((key, value) {
        if (value is Map) {
          final isRead = value['isRead'] as bool? ?? false;
          if (!isRead) {
            count++;
          }
        }
      });
      
      return count;
    });
  }

  // Add a new notification
  Future<String> addNotification({
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User must be logged in to create notifications');
    }

    final newNotificationRef = notificationsRef.push();
    final notificationId = newNotificationRef.key!;
    
    await newNotificationRef.set({
      'id': notificationId,
      'title': title,
      'message': message,
      'type': type,
      'isRead': false,
      'createdAt': DateTime.now().toIso8601String(),
      if (data != null) 'data': data,
    });
    
    return notificationId;
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    await notificationsRef.child(notificationId).update({
      'isRead': true,
    });
  }

  // Mark all notifications as read
  Future<void> markAllNotificationsAsRead() async {
    final snapshot = await notificationsRef.get();
    if (snapshot.value == null) {
      return;
    }
    
    final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
    final updates = <String, dynamic>{};
    
    data.forEach((key, value) {
      if (value is Map) {
        final isRead = value['isRead'] as bool? ?? false;
        if (!isRead) {
          updates['$key/isRead'] = true;
        }
      }
    });
    
    if (updates.isNotEmpty) {
      await notificationsRef.update(updates);
    }
  }

  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    await notificationsRef.child(notificationId).remove();
  }

  // Delete all notifications
  Future<void> deleteAllNotifications() async {
    await notificationsRef.remove();
  }

  // Delete read notifications
  Future<void> deleteReadNotifications() async {
    final snapshot = await notificationsRef.get();
    if (snapshot.value == null) {
      return;
    }
    
    final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
    final updates = <String, dynamic>{};
    
    data.forEach((key, value) {
      if (value is Map) {
        final isRead = value['isRead'] as bool? ?? false;
        if (isRead) {
          updates[key.toString()] = null; // Mark for deletion
        }
      }
    });
    
    if (updates.isNotEmpty) {
      await notificationsRef.update(updates);
    }
  }

  // Customers operations
  DatabaseReference get customersRef => _database.child('customers');
  
  // Stream of all customers
  Stream<List<Map<String, dynamic>>> getCustomersStream() {
    return customersRef.onValue.map((event) {
      if (event.snapshot.value == null) {
        return <Map<String, dynamic>>[];
      }
      
      final Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
      final List<Map<String, dynamic>> customers = [];
      
      data.forEach((key, value) {
        if (value is Map) {
          customers.add({
            'id': key,
            ...Map<String, dynamic>.from(value),
          });
        }
      });
      
      return customers;
    });
  }

  // Get all customers once
  Future<List<Map<String, dynamic>>> getCustomers() async {
    final snapshot = await customersRef.get();
    if (snapshot.value == null) {
      return [];
    }
    
    final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
    final List<Map<String, dynamic>> customers = [];
    
    data.forEach((key, value) {
      if (value is Map) {
        customers.add({
          'id': key,
          ...Map<String, dynamic>.from(value),
        });
      }
    });
    
    return customers;
  }

  // Get a single customer by ID
  Future<Map<String, dynamic>?> getCustomer(String customerId) async {
    final snapshot = await customersRef.child(customerId).get();
    if (!snapshot.exists) {
      return null;
    }
    
    return {
      'id': customerId,
      ...Map<String, dynamic>.from(snapshot.value as Map),
    };
  }

  // Add a new customer
  Future<String> addCustomer(Map<String, dynamic> customerData) async {
    final newCustomerRef = customersRef.push();
    final customerId = newCustomerRef.key!;
    
    await newCustomerRef.set({
      ...customerData,
      'id': customerId,
      'transactionCount': 0,
      'totalSpent': 0.0,
      'createdAt': DateTime.now().toIso8601String(),
      'lastTransaction': DateTime.now().toIso8601String(),
      'createdBy': currentUserId ?? 'unknown',
    });
    
    return customerId;
  }

  // Update a customer
  Future<void> updateCustomer(String customerId, Map<String, dynamic> customerData) async {
    await customersRef.child(customerId).update({
      ...customerData,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // Delete a customer
  Future<void> deleteCustomer(String customerId) async {
    await customersRef.child(customerId).remove();
  }

  // Update customer transaction stats
  Future<void> updateCustomerTransactionStats(String customerId, double transactionTotal) async {
    final customerRef = customersRef.child(customerId);
    final snapshot = await customerRef.get();
    
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final currentCount = (data['transactionCount'] as num?)?.toInt() ?? 0;
      final currentTotal = (data['totalSpent'] as num?)?.toDouble() ?? 0.0;
      
      await customerRef.update({
        'transactionCount': currentCount + 1,
        'totalSpent': currentTotal + transactionTotal,
        'lastTransaction': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }
  }

  // Get transactions for a specific customer
  Stream<List<Map<String, dynamic>>> getCustomerTransactionsStream(String customerId) {
    return transactionsRef
        .orderByChild('customerId')
        .equalTo(customerId)
        .onValue
        .map((event) {
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

  // Get customer transactions once
  Future<List<Map<String, dynamic>>> getCustomerTransactions(String customerId) async {
    final snapshot = await transactionsRef
        .orderByChild('customerId')
        .equalTo(customerId)
        .get();
    
    if (snapshot.value == null) {
      return [];
    }
    
    final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
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
  }
}

