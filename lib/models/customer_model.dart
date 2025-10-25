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
