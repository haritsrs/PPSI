import 'package:flutter/material.dart';

class Customer {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final int transactionCount;
  final double totalSpent;
  final DateTime createdAt;
  final DateTime lastTransaction;
  final String notes;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.transactionCount,
    required this.totalSpent,
    required this.createdAt,
    required this.lastTransaction,
    this.notes = '',
  });

  // Factory constructor to create Customer from Firebase data
  factory Customer.fromFirebase(Map<String, dynamic> data) {
    DateTime createdAt;
    DateTime lastTransaction;
    
    try {
      createdAt = data['createdAt'] != null 
          ? DateTime.parse(data['createdAt'] as String)
          : DateTime.now();
    } catch (e) {
      createdAt = DateTime.now();
    }
    
    try {
      lastTransaction = data['lastTransaction'] != null
          ? DateTime.parse(data['lastTransaction'] as String)
          : DateTime.now();
    } catch (e) {
      lastTransaction = DateTime.now();
    }

    return Customer(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      email: data['email'] as String? ?? '',
      address: data['address'] as String? ?? '',
      transactionCount: (data['transactionCount'] as num?)?.toInt() ?? 0,
      totalSpent: (data['totalSpent'] as num?)?.toDouble() ?? 0.0,
      createdAt: createdAt,
      lastTransaction: lastTransaction,
      notes: data['notes'] as String? ?? '',
    );
  }

  // Convert Customer to Map for Firebase
  Map<String, dynamic> toFirebase() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'transactionCount': transactionCount,
      'totalSpent': totalSpent,
      'createdAt': createdAt.toIso8601String(),
      'lastTransaction': lastTransaction.toIso8601String(),
      'notes': notes,
    };
  }

  // Create a copy with updated fields
  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    int? transactionCount,
    double? totalSpent,
    DateTime? createdAt,
    DateTime? lastTransaction,
    String? notes,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      transactionCount: transactionCount ?? this.transactionCount,
      totalSpent: totalSpent ?? this.totalSpent,
      createdAt: createdAt ?? this.createdAt,
      lastTransaction: lastTransaction ?? this.lastTransaction,
      notes: notes ?? this.notes,
    );
  }

  String get initials {
    final names = name.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }

  String get customerTier {
    if (totalSpent >= 1000000) return 'VIP';
    if (totalSpent >= 500000) return 'Gold';
    if (totalSpent >= 100000) return 'Silver';
    return 'Bronze';
  }

  Color get tierColor {
    switch (customerTier) {
      case 'VIP':
        return const Color(0xFF8B5CF6);
      case 'Gold':
        return const Color(0xFFF59E0B);
      case 'Silver':
        return const Color(0xFF6B7280);
      default:
        return const Color(0xFFCD7F32);
    }
  }
}
