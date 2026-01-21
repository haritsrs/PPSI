import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'database_service.dart';
import 'auth_service.dart';
import '../utils/security_utils.dart';

/// Service for exporting all user data for GDPR compliance
class DataExportService {
  final DatabaseService _databaseService = DatabaseService();
  final EncryptionHelper _encryptionHelper = EncryptionHelper();

  /// Export all user data to a JSON file
  Future<File?> exportAllUserData() async {
    try {
      final user = AuthService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final exportData = <String, dynamic>{
        'exportDate': DateTime.now().toIso8601String(),
        'userId': user.uid,
        'userEmail': user.email,
        'userDisplayName': user.displayName,
        'userCreationTime': user.metadata.creationTime?.toIso8601String(),
        'userLastSignInTime': user.metadata.lastSignInTime?.toIso8601String(),
        'userEmailVerified': user.emailVerified,
        'data': <String, dynamic>{},
      };

      // Export products
      try {
        final products = await _databaseService.getProducts();
        exportData['data']['products'] = products;
      } catch (e) {
        exportData['data']['products'] = {'error': 'Failed to export: $e'};
      }

      // Export transactions (get from stream snapshot)
      try {
        final transactions = <Map<String, dynamic>>[];
        final stream = _databaseService.getTransactionsStream();
        await for (final transactionList in stream.take(1)) {
          transactions.addAll(transactionList);
          break;
        }
        exportData['data']['transactions'] = transactions;
      } catch (e) {
        exportData['data']['transactions'] = {'error': 'Failed to export: $e'};
      }

      // Export customers
      try {
        final customers = await _databaseService.getCustomers();
        // Decrypt PII fields for export
        final decryptedCustomers = customers.map((customer) {
          final decrypted = Map<String, dynamic>.from(customer);
          if (decrypted['emailEncrypted'] == true && decrypted['email'] is String) {
            decrypted['email'] = _encryptionHelper.decryptIfPossible(decrypted['email'] as String) ?? '';
          }
          if (decrypted['phoneEncrypted'] == true && decrypted['phone'] is String) {
            decrypted['phone'] = _encryptionHelper.decryptIfPossible(decrypted['phone'] as String) ?? '';
          }
          if (decrypted['addressEncrypted'] == true && decrypted['address'] is String) {
            decrypted['address'] = _encryptionHelper.decryptIfPossible(decrypted['address'] as String) ?? '';
          }
          decrypted.remove('emailEncrypted');
          decrypted.remove('phoneEncrypted');
          decrypted.remove('addressEncrypted');
          return decrypted;
        }).toList();
        exportData['data']['customers'] = decryptedCustomers;
      } catch (e) {
        exportData['data']['customers'] = {'error': 'Failed to export: $e'};
      }

      // Export settings via Firebase Database directly
      try {
        final userId = user.uid;
        final database = FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL: DatabaseService.databaseURL,
        );
        final settingsRef = database.ref('users/$userId/settings');
        final snapshot = await settingsRef.get();
        if (snapshot.exists && snapshot.value != null) {
          exportData['data']['settings'] = snapshot.value;
        } else {
          exportData['data']['settings'] = {};
        }
      } catch (e) {
        exportData['data']['settings'] = {'error': 'Failed to export: $e'};
      }

      // Export notifications
      try {
        final notifications = <Map<String, dynamic>>[];
        final stream = _databaseService.getNotificationsStream();
        await for (final notificationList in stream.take(1)) {
          notifications.addAll(notificationList);
          break;
        }
        exportData['data']['notifications'] = notifications;
      } catch (e) {
        exportData['data']['notifications'] = {'error': 'Failed to export: $e'};
      }

      // Export audit logs via Firebase Database directly
      try {
        final userId = user.uid;
        final database = FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL: DatabaseService.databaseURL,
        );
        final auditLogsRef = database.ref('users/$userId/auditLogs');
        final snapshot = await auditLogsRef.get();
        final auditLogs = <Map<String, dynamic>>[];
        if (snapshot.exists && snapshot.value != null) {
          final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
          data.forEach((key, value) {
            if (value is Map) {
              auditLogs.add({
                'id': key,
                ...Map<String, dynamic>.from(value),
              });
            }
          });
        }
        exportData['data']['auditLogs'] = auditLogs;
      } catch (e) {
        exportData['data']['auditLogs'] = {'error': 'Failed to export: $e'};
      }

      // Convert to JSON with pretty printing
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      // Save to file
      final documentsDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'user_data_export_$timestamp.json';
      final file = File('${documentsDir.path}/$fileName');
      await file.writeAsString(jsonString);

      return file;
    } catch (e) {
      throw Exception('Failed to export user data: $e');
    }
  }

  /// Share the exported data file
  Future<void> shareExportedData(File file) async {
    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Ekspor Data Saya - KiosDarma',
        subject: 'Ekspor Data Pengguna',
      );
    } catch (e) {
      throw Exception('Failed to share exported data: $e');
    }
  }
}


