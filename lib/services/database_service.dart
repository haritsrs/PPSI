import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../utils/app_exception.dart';
import '../utils/error_helper.dart';
import '../utils/security_utils.dart';

class DatabaseService {
  // Database URL from environment variable, with fallback for backward compatibility
  static String get databaseURL => dotenv.env['FIREBASE_DATABASE_URL'] ?? 
    'https://gunadarma-pos-marketplace-default-rtdb.asia-southeast1.firebasedatabase.app/';
  
  late final DatabaseReference _database;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final EncryptionHelper _encryptionHelper = EncryptionHelper();

  DatabaseService() {
    _database = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: databaseURL,
    ).ref();
  }

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Helper method to get user-scoped reference
  DatabaseReference _getUserRef(String path) {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User must be logged in to access $path');
    }
    return _database.child('users').child(userId).child(path);
  }

  // Products operations
  DatabaseReference get productsRef => _getUserRef('products');
  DatabaseReference get auditLogsRef => _getUserRef('auditLogs');
  
  Future<void> _logAuditEvent(String action, Map<String, dynamic> payload) async {
    try {
      final sanitizedDetails = SecurityUtils.sanitizeMap(payload);
      await auditLogsRef.push().set({
        'action': action,
        'details': sanitizedDetails,
        'timestamp': DateTime.now().toIso8601String(),
        'userId': currentUserId ?? 'unknown',
      });
    } catch (error) {
      debugPrint('Audit log error for $action: $error');
    }
  }
  
  // Stream of all products
  Stream<List<Map<String, dynamic>>> getProductsStream() {
    return productsRef.onValue.handleError((error) {
      throw toAppException(
        error,
        fallbackMessage: 'Gagal memuat data produk.',
      );
    }).map((event) {
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
    try {
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
    } catch (error) {
      throw toAppException(
        error,
        fallbackMessage: 'Gagal memuat data produk.',
      );
    }
  }

  Future<({List<Map<String, dynamic>> items, String? lastKey, bool hasMore})> fetchProductsPage({
    int limit = 25,
    String? startAfterKey,
  }) async {
    assert(limit > 0, 'limit must be greater than zero');

    try {
      Query query = productsRef.orderByKey().limitToFirst(limit);
      if (startAfterKey != null && startAfterKey.isNotEmpty) {
        query = query.startAfter(startAfterKey);
      }

      final snapshot = await query.get();
      final items = <Map<String, dynamic>>[];
      String? lastKey;

      for (final child in snapshot.children) {
        final key = child.key;
        final value = child.value;
        if (key != null && value is Map) {
          items.add({
            'id': key,
            ...Map<String, dynamic>.from(value),
          });
          lastKey = key;
        }
      }

      final hasMore = snapshot.children.length == limit;
      return (items: items, lastKey: lastKey, hasMore: hasMore);
    } catch (error) {
      throw toAppException(
        error,
        fallbackMessage: 'Gagal memuat data produk.',
      );
    }
  }

  // Add a new product
  Future<String> addProduct(Map<String, dynamic> productData) async {
    try {
      if (!RateLimiter.allow('add_product', interval: const Duration(milliseconds: 900))) {
        throw const RateLimitException('Terlalu banyak permintaan penambahan produk. Coba lagi sesaat lagi.');
      }
      final sanitizedData = SecurityUtils.sanitizeMap(productData);
      final newProductRef = productsRef.push();
      await newProductRef.set({
        ...sanitizedData,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'createdBy': currentUserId ?? 'unknown',
      });
      await _logAuditEvent('add_product', {
        'productId': newProductRef.key,
        'name': sanitizedData['name'] ?? '',
        'category': sanitizedData['category'] ?? '',
      });
      return newProductRef.key!;
    } catch (error) {
      throw toAppException(
        error,
        fallbackMessage: 'Gagal menambahkan produk.',
      );
    }
  }

  // Update a product
  Future<void> updateProduct(String productId, Map<String, dynamic> productData) async {
    try {
      if (!RateLimiter.allow('update_product', interval: const Duration(milliseconds: 600))) {
        throw const RateLimitException('Terlalu banyak perubahan produk dalam waktu singkat.');
      }
      final sanitizedData = SecurityUtils.sanitizeMap(productData);
      await productsRef.child(productId).update({
        ...sanitizedData,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      await _logAuditEvent('update_product', {
        'productId': productId,
        'name': sanitizedData['name'] ?? '',
        'updatedFields': sanitizedData.keys.toList(),
      });
    } catch (error) {
      throw toAppException(
        error,
        fallbackMessage: 'Gagal memperbarui produk.',
      );
    }
  }

  // Delete a product
  Future<void> deleteProduct(String productId) async {
    try {
      if (!RateLimiter.allow('delete_product', interval: const Duration(milliseconds: 600))) {
        throw const RateLimitException('Penghapusan terlalu sering. Tunggu sebentar sebelum mencoba lagi.');
      }
      final snapshot = await productsRef.child(productId).get();
      final currentData = snapshot.value;
      await productsRef.child(productId).remove();
      await _logAuditEvent('delete_product', {
        'productId': productId,
        if (currentData is Map && currentData['name'] != null)
          'name': SecurityUtils.sanitizeInput(currentData['name'] as String),
      });
    } catch (error) {
      throw toAppException(
        error,
        fallbackMessage: 'Gagal menghapus produk.',
      );
    }
  }

  // Update product stock with history tracking
  Future<void> updateProductStock(
    String productId,
    int newStock, {
    String? reason,
    String? notes,
  }) async {
    try {
      if (!RateLimiter.allow('update_product_stock', interval: const Duration(milliseconds: 400))) {
        throw const RateLimitException('Permintaan pembaruan stok terlalu sering. Coba lagi sebentar lagi.');
      }
      final sanitizedReason = SecurityUtils.sanitizeInput(reason ?? 'Manual Adjustment');
      final sanitizedNotes = SecurityUtils.sanitizeInput(notes ?? '');
      final productRef = productsRef.child(productId);
      final snapshot = await productRef.get();
      
      if (!snapshot.exists) {
        throw const NotFoundException('Produk tidak ditemukan.');
      }
      
      final productData = Map<String, dynamic>.from(snapshot.value as Map);
      final oldStock = (productData['stock'] as num?)?.toInt() ?? 0;
      final minStock = (productData['minStock'] as num?)?.toInt() ?? 10;
      
      // Update stock
      await productRef.update({
        'stock': newStock,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      
      // Record stock history
      final stockHistoryRef = _getUserRef('stockHistory').child(productId).push();
      await stockHistoryRef.set({
        'productId': productId,
        'productName': productData['name'] as String? ?? '',
        'oldStock': oldStock,
        'newStock': newStock,
        'difference': newStock - oldStock,
        'reason': sanitizedReason,
        'notes': sanitizedNotes,
        'createdAt': DateTime.now().toIso8601String(),
        'createdBy': currentUserId ?? 'unknown',
      });
      
      // Check for low stock and create notification
      if (newStock <= minStock && oldStock > minStock) {
        // Stock just went low
        try {
          await addNotification(
            title: 'Stok Rendah',
            message: '${productData['name']} stok rendah (${newStock} unit)',
            type: 'low_stock',
            data: {
              'productId': productId,
              'productName': productData['name'],
              'currentStock': newStock,
              'minStock': minStock,
            },
          );
        } catch (e) {
          // Ignore notification errors
          debugPrint('Error creating low stock notification: $e');
        }
      }
      
      // Check for out of stock
      if (newStock == 0 && oldStock > 0) {
        try {
          await addNotification(
            title: 'Stok Habis',
            message: '${productData['name']} stok habis',
            type: 'out_of_stock',
            data: {
              'productId': productId,
              'productName': productData['name'],
            },
          );
        } catch (e) {
          // Ignore notification errors
          debugPrint('Error creating out of stock notification: $e');
        }
      }

      await _logAuditEvent('update_product_stock', {
        'productId': productId,
        'oldStock': oldStock,
        'newStock': newStock,
        'reason': sanitizedReason,
      });
    } catch (error) {
      throw toAppException(
        error,
        fallbackMessage: 'Gagal memperbarui stok produk.',
      );
    }
  }

  // Decrement product stock (for sales) with history tracking
  Future<void> decrementProductStock(String productId, int quantity) async {
    try {
      final productRef = productsRef.child(productId);
      final snapshot = await productRef.get();
      
      if (!snapshot.exists) {
        throw const NotFoundException('Produk tidak ditemukan.');
      }
      
      final productData = Map<String, dynamic>.from(snapshot.value as Map);
      final currentStock = (productData['stock'] as num?)?.toInt() ?? 0;
      final minStock = (productData['minStock'] as num?)?.toInt() ?? 10;
      final newStock = (currentStock - quantity).clamp(0, double.infinity).toInt();
      
      await productRef.update({
        'stock': newStock,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      
      // Record stock history
      final stockHistoryRef = _getUserRef('stockHistory').child(productId).push();
      await stockHistoryRef.set({
        'productId': productId,
        'productName': productData['name'] as String? ?? '',
        'oldStock': currentStock,
        'newStock': newStock,
        'difference': -quantity,
        'reason': 'Penjualan',
        'notes': 'Terjual $quantity unit',
        'createdAt': DateTime.now().toIso8601String(),
        'createdBy': currentUserId ?? 'unknown',
      });
      
      // Check for low stock and create notification
      if (newStock <= minStock && currentStock > minStock) {
        try {
          await addNotification(
            title: 'Stok Rendah',
            message: '${productData['name']} stok rendah (${newStock} unit)',
            type: 'low_stock',
            data: {
              'productId': productId,
              'productName': productData['name'],
              'currentStock': newStock,
              'minStock': minStock,
            },
          );
        } catch (e) {
          debugPrint('Error creating low stock notification: $e');
        }
      }
      
      // Check for out of stock
      if (newStock == 0 && currentStock > 0) {
        try {
          await addNotification(
            title: 'Stok Habis',
            message: '${productData['name']} stok habis',
            type: 'out_of_stock',
            data: {
              'productId': productId,
              'productName': productData['name'],
            },
          );
        } catch (e) {
          debugPrint('Error creating out of stock notification: $e');
        }
      }

      await _logAuditEvent('decrement_product_stock', {
        'productId': productId,
        'oldStock': currentStock,
        'newStock': newStock,
        'quantity': quantity,
      });
    } catch (error) {
      throw toAppException(
        error,
        fallbackMessage: 'Gagal memperbarui stok produk.',
      );
    }
  }

  // Get stock history for a product
  Stream<List<Map<String, dynamic>>> getStockHistoryStream(String productId) {
    return _getUserRef('stockHistory').child(productId)
        .orderByChild('createdAt')
        .onValue
        .map((event) {
      if (event.snapshot.value == null) {
        return <Map<String, dynamic>>[];
      }
      
      final Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
      final List<Map<String, dynamic>> history = [];
      
      data.forEach((key, value) {
        if (value is Map) {
          history.add({
            'id': key,
            ...Map<String, dynamic>.from(value),
          });
        }
      });
      
      return history.reversed.toList(); // Most recent first
    });
  }

  // Get all stock history
  Stream<List<Map<String, dynamic>>> getAllStockHistoryStream() {
    return _getUserRef('stockHistory')
        .orderByChild('createdAt')
        .onValue
        .map((event) {
      if (event.snapshot.value == null) {
        return <Map<String, dynamic>>[];
      }
      
      final Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
      final List<Map<String, dynamic>> history = [];
      
      data.forEach((productId, productHistory) {
        if (productHistory is Map) {
          productHistory.forEach((key, value) {
            if (value is Map) {
              history.add({
                'id': key,
                ...Map<String, dynamic>.from(value),
              });
            }
          });
        }
      });
      
      return history.reversed.toList(); // Most recent first
    });
  }

  // Bulk update stock for multiple products
  Future<void> bulkUpdateStock(List<Map<String, String>> updates) async {
    try {
      if (!RateLimiter.allow('bulk_update_stock', interval: const Duration(seconds: 1))) {
        throw const RateLimitException('Bulk update terlalu sering. Coba lagi sesaat lagi.');
      }
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('User must be logged in to update stock');
      }
      
      final batch = <String, dynamic>{};
      final historyBatch = <String, dynamic>{};
      final sanitizedUpdates = updates
          .map((update) => {
                'productId': update['productId'] ?? '',
                'stock': update['stock'] ?? '0',
                'reason': SecurityUtils.sanitizeInput(update['reason'] ?? ''),
                'notes': SecurityUtils.sanitizeInput(update['notes'] ?? ''),
              })
          .toList();
      
      for (final update in sanitizedUpdates) {
        final productId = update['productId']!;
        final newStock = int.parse(update['stock']!);
        final reason = update['reason']!.isEmpty ? 'Bulk Update' : update['reason']!;
        final notes = update['notes'] ?? '';
        
        // Get current stock
        final productRef = productsRef.child(productId);
        final snapshot = await productRef.get();
        
        if (snapshot.exists) {
          final productData = Map<String, dynamic>.from(snapshot.value as Map);
          final oldStock = (productData['stock'] as num?)?.toInt() ?? 0;
          final minStock = (productData['minStock'] as num?)?.toInt() ?? 10;
          
          // Prepare stock update (productsRef is already user-scoped)
          batch['products/$productId/stock'] = newStock;
          batch['products/$productId/updatedAt'] = DateTime.now().toIso8601String();
          
          // Prepare history entry (stockHistory is already user-scoped via _getUserRef)
          final historyKey = 'stockHistory/$productId/${DateTime.now().millisecondsSinceEpoch}';
          historyBatch[historyKey] = {
            'productId': productId,
            'productName': productData['name'] as String? ?? '',
            'oldStock': oldStock,
            'newStock': newStock,
            'difference': newStock - oldStock,
            'reason': reason,
            'notes': notes,
            'createdAt': DateTime.now().toIso8601String(),
            'createdBy': userId,
          };
          
          // Check for low stock notifications
          if (newStock <= minStock && oldStock > minStock) {
            try {
              await addNotification(
                title: 'Stok Rendah',
                message: '${productData['name']} stok rendah (${newStock} unit)',
                type: 'low_stock',
                data: {
                  'productId': productId,
                  'productName': productData['name'],
                  'currentStock': newStock,
                  'minStock': minStock,
                },
              );
            } catch (e) {
              debugPrint('Error creating low stock notification: $e');
            }
          }
        }
      }
      
      // Execute batch update using user-scoped references
      if (batch.isNotEmpty) {
        final userScopedBatch = <String, dynamic>{};
        batch.forEach((key, value) {
          userScopedBatch['users/$userId/$key'] = value;
        });
        await _database.update(userScopedBatch);
      }
      
      // Add history entries using user-scoped references
      if (historyBatch.isNotEmpty) {
        final userScopedHistoryBatch = <String, dynamic>{};
        historyBatch.forEach((key, value) {
          userScopedHistoryBatch['users/$userId/$key'] = value;
        });
        await _database.update(userScopedHistoryBatch);
      }

      if (sanitizedUpdates.isNotEmpty) {
        await _logAuditEvent('bulk_update_stock', {
          'count': sanitizedUpdates.length,
          'productIds': sanitizedUpdates.map((update) => update['productId']).toList(),
          'reasons': sanitizedUpdates.map((update) => update['reason']).toSet().toList(),
        });
      }
    } catch (error) {
      throw toAppException(
        error,
        fallbackMessage: 'Gagal memperbarui stok produk secara massal.',
      );
    }
  }

  // Transactions operations
  DatabaseReference get transactionsRef => _getUserRef('transactions');
  
  // Withdrawals operations
  DatabaseReference get withdrawalsRef => _getUserRef('withdrawals');
  
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
    double? discount,
  }) async {
    try {
      if (!RateLimiter.allow('add_transaction', interval: const Duration(milliseconds: 500))) {
        throw const RateLimitException('Terlalu banyak transaksi dibuat dalam waktu bersamaan.');
      }
      
      // Validate items
      if (items.isEmpty) {
        throw Exception('Transaksi harus memiliki minimal 1 item. [DIAG: items_empty]');
      }
      
      // Validate user is logged in
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('User tidak terautentikasi. Silakan login ulang. [DIAG: user_not_authenticated]');
      }
      
      final newTransactionRef = transactionsRef.push();
      final transactionId = newTransactionRef.key!;
      
      if (transactionId.isEmpty) {
        throw Exception('Gagal membuat ID transaksi. [DIAG: transaction_id_empty]');
      }

      final sanitizedItems = items
          .map((item) {
            try {
              final sanitized = Map<String, dynamic>.from(item);
              if (sanitized['productName'] is String) {
                sanitized['productName'] = SecurityUtils.sanitizeInput(sanitized['productName'] as String);
              }
              // Validate required fields
              if (sanitized['productId'] == null || sanitized['productId'].toString().isEmpty) {
                throw Exception('Item tidak memiliki productId. [DIAG: missing_product_id]');
              }
              if (sanitized['quantity'] == null || (sanitized['quantity'] as num) <= 0) {
                throw Exception('Item memiliki quantity tidak valid. [DIAG: invalid_quantity]');
              }
              return sanitized;
            } catch (e) {
              throw Exception('Error memproses item: $e');
            }
          })
          .toList();

      final sanitizedPaymentMethod = SecurityUtils.sanitizeInput(paymentMethod);
      final sanitizedCustomerName =
          customerName != null ? SecurityUtils.sanitizeInput(customerName) : null;
      
      final transactionData = {
        'id': transactionId,
        'items': sanitizedItems,
        'subtotal': subtotal,
        'tax': tax,
        'total': total,
        'paymentMethod': sanitizedPaymentMethod,
        'cashAmount': cashAmount,
        'change': change,
        'createdAt': DateTime.now().toIso8601String(),
        'createdBy': userId,
        'status': 'Selesai',
        if (customerId != null && customerId.isNotEmpty) 'customerId': customerId,
        if (sanitizedCustomerName != null && sanitizedCustomerName.isNotEmpty)
          'customerName': _encryptionHelper.encrypt(sanitizedCustomerName),
        if (sanitizedCustomerName != null && sanitizedCustomerName.isNotEmpty) 'customerNameEncrypted': true,
        if (discount != null && discount > 0) 'discount': discount,
      };
      
      // Save transaction
      try {
        await newTransactionRef.set(transactionData);
        debugPrint('Transaction saved successfully: $transactionId');
      } catch (e) {
        // Include specific Firebase error codes for debugging permission issues
        final errorDetails = e.toString();
        if (errorDetails.contains('permission-denied')) {
          throw Exception('Gagal menyimpan transaksi: Akses ke database ditolak. Silakan logout dan login kembali, atau hubungi admin jika masalah berlanjut. [DIAG: firebase_permission_denied | Path: users/$userId/transactions/$transactionId | Error: $e]');
        }
        throw Exception('Gagal menyimpan transaksi ke database: $e [DIAG: save_failed | TransactionId: $transactionId]');
      }
      
      // Update stock for each item
      final List<String> stockErrors = [];
      for (var item in items) {
        try {
          final productId = item['productId'] as String?;
          final quantity = item['quantity'] as int?;
          
          if (productId == null || productId.isEmpty) {
            stockErrors.add('ProductId kosong');
            continue;
          }
          
          if (quantity == null || quantity <= 0) {
            stockErrors.add('Quantity tidak valid untuk produk $productId');
            continue;
          }
          
          await decrementProductStock(productId, quantity);
        } catch (e) {
          stockErrors.add('Error update stok untuk ${item['productId']}: $e');
          debugPrint('Error decrementing stock for ${item['productId']}: $e');
        }
      }
      
      if (stockErrors.isNotEmpty) {
        debugPrint('Stock update errors (transaction still saved): ${stockErrors.join(", ")}');
        // Don't throw - transaction is already saved, just log the errors
      }
      
      // Update customer transaction stats if customerId is provided
      if (customerId != null && customerId.isNotEmpty) {
        try {
          await updateCustomerTransactionStats(customerId, total);
        } catch (e) {
          debugPrint('Error updating customer stats: $e');
          // Don't throw - transaction is already saved
        }
      }

      try {
        await _logAuditEvent('add_transaction', {
          'transactionId': transactionId,
          'itemCount': sanitizedItems.length,
          'total': total,
          'paymentMethod': sanitizedPaymentMethod,
          if (customerId != null) 'customerId': customerId,
        });
      } catch (e) {
        debugPrint('Error logging audit event: $e');
        // Don't throw - transaction is already saved
      }
      
      return transactionId;
    } catch (error) {
      debugPrint('Error in addTransaction: $error');
      throw toAppException(
        error,
        fallbackMessage: 'Gagal memproses transaksi. [DIAG: ${error.toString()}]',
      );
    }
  }

  // Get transactions stream
  Stream<List<Map<String, dynamic>>> getTransactionsStream() {
    return transactionsRef.orderByChild('createdAt').onValue.handleError((error) {
      throw toAppException(
        error,
        fallbackMessage: 'Gagal memuat data transaksi.',
      );
    }).map((event) {
      if (event.snapshot.value == null) {
        return <Map<String, dynamic>>[];
      }
      
      final Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
      final List<Map<String, dynamic>> transactions = [];
      
      data.forEach((key, value) {
        if (value is Map) {
          final mapped = Map<String, dynamic>.from(value);
          if (mapped['customerNameEncrypted'] == true && mapped['customerName'] is String) {
            final decrypted = _encryptionHelper.decryptIfPossible(mapped['customerName'] as String);
            if (decrypted != null) {
              mapped['customerName'] = decrypted;
            }
          }
          mapped.remove('customerNameEncrypted');
          final sanitized = SecurityUtils.sanitizeMap(mapped);
          sanitized.remove('customerNameEncrypted');
          transactions.add({
            'id': key,
            ...sanitized,
          });
        }
      });
      
      return transactions.reversed.toList(); // Most recent first
    });
  }

  // Get total store balance from QRIS and VirtualAccount transactions minus withdrawals
  Stream<double> getStoreBalanceStream() {
    // Use a simpler approach: combine transactions and withdrawals in a single calculation
    // Listen to both streams and emit whenever either changes
    final controller = StreamController<double>.broadcast();
    double transactionsTotal = 0.0;
    double withdrawalsTotal = 0.0;
    bool hasTransactions = false;
    bool hasWithdrawals = false;
    
    void emitBalance() {
      // Emit balance once we have at least transactions data
      // Withdrawals default to 0 if not loaded yet
      if (hasTransactions || hasWithdrawals) {
        final balance = (transactionsTotal - withdrawalsTotal).clamp(0.0, double.infinity);
        if (!controller.isClosed) {
          controller.add(balance);
        }
      }
    }
    
    // Listen to transactions
    final transactionsSubscription = transactionsRef.onValue.listen((event) {
      transactionsTotal = 0.0;
      if (event.snapshot.value != null) {
        final Map<dynamic, dynamic> transactionData = event.snapshot.value as Map<dynamic, dynamic>;
        transactionData.forEach((key, value) {
          if (value is Map) {
            final paymentMethod = value['paymentMethod'] as String?;
            // Only include QRIS and VirtualAccount transactions (exclude Cash/Tunai)
            if (paymentMethod == 'QRIS' || paymentMethod == 'VirtualAccount') {
              final total = value['total'];
              if (total != null) {
                transactionsTotal += (total as num).toDouble();
              }
            }
          }
        });
      }
      hasTransactions = true;
      emitBalance();
    }, onError: (error) {
      if (!controller.isClosed) {
        controller.addError(error);
      }
    });
    
    // Listen to withdrawals
    final withdrawalsSubscription = withdrawalsRef.onValue.listen((event) {
      withdrawalsTotal = 0.0;
      if (event.snapshot.value != null) {
        final Map<dynamic, dynamic> withdrawalData = event.snapshot.value as Map<dynamic, dynamic>;
        withdrawalData.forEach((key, value) {
          if (value is Map) {
            final amount = value['amount'];
            final status = value['status'] as String? ?? 'pending';
            // Count all withdrawals (pending, processing, completed) to reduce balance immediately
            // Rejected withdrawals don't count
            if (status != 'rejected' && amount != null) {
              withdrawalsTotal += (amount as num).toDouble();
            }
          }
        });
      }
      hasWithdrawals = true;
      emitBalance();
    }, onError: (error) {
      if (!controller.isClosed) {
        controller.addError(error);
      }
    });
    
    // Clean up subscriptions when controller is closed
    controller.onCancel = () {
      transactionsSubscription.cancel();
      withdrawalsSubscription.cancel();
    };
    
    return controller.stream;
  }

  // Get total revenue (penghasilan) from ALL transactions for reporting purposes
  Stream<double> getRevenueStream() {
    return transactionsRef.onValue.map((event) {
      if (event.snapshot.value == null) {
        return 0.0;
      }
      
      final Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
      double totalRevenue = 0.0;
      
      data.forEach((key, value) {
        if (value is Map) {
          final total = value['total'];
          if (total != null) {
            totalRevenue += (total as num).toDouble();
          }
        }
      });
      
      return totalRevenue;
    });
  }

  // Get today's revenue (only QRIS and VirtualAccount for consistency with saldo toko)
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
          final paymentMethod = value['paymentMethod'] as String?;
          // Only include QRIS and VirtualAccount transactions (exclude Cash/Tunai)
          if (paymentMethod == 'QRIS' || paymentMethod == 'VirtualAccount') {
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
        }
      });
      
      return todayRevenue;
    });
  }

  // Get yesterday's revenue (only QRIS and VirtualAccount for consistency with saldo toko)
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
          final paymentMethod = value['paymentMethod'] as String?;
          // Only include QRIS and VirtualAccount transactions (exclude Cash/Tunai)
          if (paymentMethod == 'QRIS' || paymentMethod == 'VirtualAccount') {
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
        }
      });
      
      return yesterdayRevenue;
    });
  }

  // Get categories from products
  Future<List<String>> getCategories() async {
    try {
      final products = await getProducts();
      final categories = <String>{};
      
      for (var product in products) {
        final category = product['category'] as String?;
        if (category != null && category.isNotEmpty) {
          categories.add(category);
        }
      }
      
      return categories.toList()..sort();
    } catch (error) {
      throw toAppException(
        error,
        fallbackMessage: 'Gagal memuat kategori produk.',
      );
    }
  }

  // Notifications operations
  DatabaseReference get notificationsRef => _getUserRef('notifications');

  // Get notifications stream for current user
  Stream<List<Map<String, dynamic>>> getNotificationsStream() {
    if (currentUserId == null) {
      return Stream.value([]);
    }
    
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
  DatabaseReference get customersRef => _getUserRef('customers');
  
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
    
    // Prepare customer data with encrypted PII fields
    final sanitizedData = Map<String, dynamic>.from(customerData);
    
    // Encrypt PII fields (email, phone, address) if they exist
    if (sanitizedData['email'] is String && (sanitizedData['email'] as String).isNotEmpty) {
      sanitizedData['email'] = _encryptionHelper.encrypt(sanitizedData['email'] as String);
      sanitizedData['emailEncrypted'] = true;
    }
    if (sanitizedData['phone'] is String && (sanitizedData['phone'] as String).isNotEmpty) {
      sanitizedData['phone'] = _encryptionHelper.encrypt(sanitizedData['phone'] as String);
      sanitizedData['phoneEncrypted'] = true;
    }
    if (sanitizedData['address'] is String && (sanitizedData['address'] as String).isNotEmpty) {
      sanitizedData['address'] = _encryptionHelper.encrypt(sanitizedData['address'] as String);
      sanitizedData['addressEncrypted'] = true;
    }
    
    // Sanitize name and notes (non-PII but still need sanitization)
    if (sanitizedData['name'] is String) {
      sanitizedData['name'] = SecurityUtils.sanitizeInput(sanitizedData['name'] as String);
    }
    if (sanitizedData['notes'] is String) {
      sanitizedData['notes'] = SecurityUtils.sanitizeInput(sanitizedData['notes'] as String);
    }
    
    await newCustomerRef.set({
      ...sanitizedData,
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
    // Prepare customer data with encrypted PII fields
    final sanitizedData = Map<String, dynamic>.from(customerData);
    
    // Encrypt PII fields (email, phone, address) if they exist
    if (sanitizedData.containsKey('email') && sanitizedData['email'] is String) {
      final emailValue = sanitizedData['email'] as String;
      if (emailValue.isNotEmpty) {
        sanitizedData['email'] = _encryptionHelper.encrypt(emailValue);
        sanitizedData['emailEncrypted'] = true;
      } else {
        sanitizedData['email'] = '';
        sanitizedData['emailEncrypted'] = false;
      }
    }
    if (sanitizedData.containsKey('phone') && sanitizedData['phone'] is String) {
      final phoneValue = sanitizedData['phone'] as String;
      if (phoneValue.isNotEmpty) {
        sanitizedData['phone'] = _encryptionHelper.encrypt(phoneValue);
        sanitizedData['phoneEncrypted'] = true;
      } else {
        sanitizedData['phone'] = '';
        sanitizedData['phoneEncrypted'] = false;
      }
    }
    if (sanitizedData.containsKey('address') && sanitizedData['address'] is String) {
      final addressValue = sanitizedData['address'] as String;
      if (addressValue.isNotEmpty) {
        sanitizedData['address'] = _encryptionHelper.encrypt(addressValue);
        sanitizedData['addressEncrypted'] = true;
      } else {
        sanitizedData['address'] = '';
        sanitizedData['addressEncrypted'] = false;
      }
    }
    
    // Sanitize name and notes (non-PII but still need sanitization)
    if (sanitizedData['name'] is String) {
      sanitizedData['name'] = SecurityUtils.sanitizeInput(sanitizedData['name'] as String);
    }
    if (sanitizedData['notes'] is String) {
      sanitizedData['notes'] = SecurityUtils.sanitizeInput(sanitizedData['notes'] as String);
    }
    
    await customersRef.child(customerId).update({
      ...sanitizedData,
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

  // Cancel a transaction (restore stock and mark as cancelled)
  Future<void> cancelTransaction(String transactionId) async {
    final transactionRef = transactionsRef.child(transactionId);
    final snapshot = await transactionRef.get();
    
    if (!snapshot.exists) {
      throw Exception('Transaction not found');
    }
    
    final transactionData = Map<String, dynamic>.from(snapshot.value as Map);
    final status = transactionData['status'] as String? ?? 'Selesai';
    
    if (status == 'Dibatalkan') {
      throw Exception('Transaction already cancelled');
    }
    
    // Restore stock for each item
    final items = transactionData['items'] as List<dynamic>? ?? [];
    for (var item in items) {
      final productId = item['productId'] as String;
      final quantity = item['quantity'] as int;
      
      // Increment stock back
      final productRef = productsRef.child(productId);
      final productSnapshot = await productRef.child('stock').get();
      
      if (productSnapshot.exists) {
        final currentStock = (productSnapshot.value as num).toInt();
        await productRef.update({
          'stock': currentStock + quantity,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
    }
    
    // Update transaction status
    await transactionRef.update({
      'status': 'Dibatalkan',
      'cancelledAt': DateTime.now().toIso8601String(),
      'cancelledBy': currentUserId ?? 'unknown',
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // Update transaction status
  Future<void> updateTransactionStatus(String transactionId, String status) async {
    await transactionsRef.child(transactionId).update({
      'status': status,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // Get a single transaction by ID
  Future<Map<String, dynamic>?> getTransaction(String transactionId) async {
    try {
      final snapshot = await transactionsRef.child(transactionId).get();
      if (!snapshot.exists) {
        return null;
      }
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      if (data['customerNameEncrypted'] == true && data['customerName'] is String) {
        final decrypted = _encryptionHelper.decryptIfPossible(data['customerName'] as String);
        if (decrypted != null) {
          data['customerName'] = decrypted;
        }
      }
      data.remove('customerNameEncrypted');
      final sanitized = SecurityUtils.sanitizeMap(data);
      sanitized.remove('customerNameEncrypted');
      return {
        'id': transactionId,
        ...sanitized,
      };
    } catch (error) {
      throw toAppException(
        error,
        fallbackMessage: 'Gagal memuat detail transaksi.',
      );
    }
  }

  // Add a withdrawal (pencairan)
  Future<String> addWithdrawal({
    required double amount,
    required String bankName,
    required String accountNumber,
    required String accountHolderName,
    String? notes,
  }) async {
    final newWithdrawalRef = withdrawalsRef.push();
    final withdrawalId = newWithdrawalRef.key!;
    
    final sanitizedBankName = SecurityUtils.sanitizeInput(bankName);
    final sanitizedAccountHolderName = SecurityUtils.sanitizeInput(accountHolderName);
    final sanitizedAccountNumber = SecurityUtils.sanitizeNumber(accountNumber).replaceAll(RegExp(r'[^0-9]'), '');
    final sanitizedNotes = SecurityUtils.sanitizeInput(notes ?? '');

    final withdrawalData = {
      'id': withdrawalId,
      'amount': amount,
      'bankName': sanitizedBankName,
      'accountNumber': sanitizedAccountNumber,
      'accountHolderName': sanitizedAccountHolderName,
      'status': 'pending', // pending, processing, completed, rejected
      'notes': sanitizedNotes,
      'createdAt': DateTime.now().toIso8601String(),
      'createdBy': currentUserId ?? 'unknown',
    };
    
    await newWithdrawalRef.set(withdrawalData);
    await _logAuditEvent('add_withdrawal', {
      'withdrawalId': withdrawalId,
      'amount': amount,
      'bankName': sanitizedBankName,
    });
    
    // Create notification for withdrawal request
    try {
      await addNotification(
        title: 'Permintaan Pencairan',
        message: 'Permintaan pencairan sebesar Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} telah diajukan',
        type: 'withdrawal',
        data: {
          'withdrawalId': withdrawalId,
          'amount': amount,
          'status': 'pending',
        },
      );
    } catch (e) {
      // Ignore notification errors
    }
    
    return withdrawalId;
  }

  // Get withdrawals stream
  Stream<List<Map<String, dynamic>>> getWithdrawalsStream() {
    return withdrawalsRef.orderByChild('createdAt').onValue.map((event) {
      if (event.snapshot.value == null) {
        return <Map<String, dynamic>>[];
      }
      
      final Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
      final List<Map<String, dynamic>> withdrawals = [];
      
      data.forEach((key, value) {
        if (value is Map) {
          withdrawals.add({
            'id': key,
            ...Map<String, dynamic>.from(value),
          });
        }
      });
      
      return withdrawals.reversed.toList(); // Most recent first
    });
  }

  // Update withdrawal status
  Future<void> updateWithdrawalStatus(String withdrawalId, String status, {String? notes}) async {
    final updates = <String, dynamic>{
      'status': status,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    if (notes != null) {
      updates['notes'] = notes;
    }
    await withdrawalsRef.child(withdrawalId).update(updates);
  }

  // Get total withdrawals amount (all statuses except rejected)
  Future<double> getTotalWithdrawals() async {
    final snapshot = await withdrawalsRef.get();
    if (snapshot.value == null) {
      return 0.0;
    }
    
    final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
    double totalWithdrawals = 0.0;
    
    data.forEach((key, value) {
      if (value is Map) {
        final amount = value['amount'];
        final status = value['status'] as String? ?? 'pending';
        // Count all withdrawals except rejected
        if (status != 'rejected' && amount != null) {
          totalWithdrawals += (amount as num).toDouble();
        }
      }
    });
    
    return totalWithdrawals;
  }

  // Delete all user data (for account deletion)
  Future<void> deleteAllUserData() async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User must be logged in');
    }

    try {
      // Delete all user data in a single operation
      final userRef = _database.child('users').child(userId);
      await userRef.remove();
    } catch (error) {
      throw toAppException(
        error,
        fallbackMessage: 'Gagal menghapus data pengguna.',
      );
    }
  }

  // User Profile operations
  DatabaseReference get userProfileRef => _database.child('users').child(currentUserId!).child('profile');
  
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final snapshot = await userProfileRef.get();
      if (!snapshot.exists || snapshot.value == null) {
        return null;
      }
      return Map<String, dynamic>.from(snapshot.value as Map);
    } catch (error) {
      throw toAppException(
        error,
        fallbackMessage: 'Gagal memuat profil pengguna.',
      );
    }
  }

  Future<void> updateUserProfile(Map<String, dynamic> profileData) async {
    try {
      final sanitizedData = SecurityUtils.sanitizeMap(profileData);
      sanitizedData['updatedAt'] = DateTime.now().toIso8601String();
      
      await userProfileRef.update(sanitizedData);
      
      await _logAuditEvent('update_profile', {
        'fields': sanitizedData.keys.toList(),
      });
    } catch (error) {
      throw toAppException(
        error,
        fallbackMessage: 'Gagal memperbarui profil pengguna.',
      );
    }
  }

  Future<void> updateProfilePicture(String imageUrl) async {
    try {
      await userProfileRef.update({
        'photoURL': imageUrl,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      
      await _logAuditEvent('update_profile_picture', {
        'imageUrl': imageUrl,
      });
    } catch (error) {
      throw toAppException(
        error,
        fallbackMessage: 'Gagal memperbarui foto profil.',
      );
    }
  }

  // Business settings operations
  DatabaseReference get businessSettingsRef => _getUserRef('settings/business');
  
  Future<Map<String, dynamic>?> getBusinessSettings() async {
    try {
      final snapshot = await businessSettingsRef.get();
      if (!snapshot.exists || snapshot.value == null) {
        return null;
      }
      return Map<String, dynamic>.from(snapshot.value as Map);
    } catch (error) {
      throw toAppException(
        error,
        fallbackMessage: 'Gagal memuat pengaturan bisnis.',
      );
    }
  }

  Future<void> updateBusinessSettings(Map<String, dynamic> settings) async {
    try {
      final sanitizedData = SecurityUtils.sanitizeMap(settings);
      sanitizedData['updatedAt'] = DateTime.now().toIso8601String();
      
      await businessSettingsRef.update(sanitizedData);
      
      await _logAuditEvent('update_business_settings', {
        'fields': sanitizedData.keys.toList(),
      });
    } catch (error) {
      throw toAppException(
        error,
        fallbackMessage: 'Gagal memperbarui pengaturan bisnis.',
      );
    }
  }
}