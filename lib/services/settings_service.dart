import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class SettingsService {
  static const String _prefsKeyPrefix = 'settings_';
  static const String databaseURL = 'https://gunadarma-pos-marketplace-default-rtdb.asia-southeast1.firebasedatabase.app/';
  static final FirebaseDatabase _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: databaseURL,
  );
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Settings keys
  static const String keyNotificationsEnabled = 'notifications_enabled';
  static const String keySoundEnabled = 'sound_enabled';
  static const String keyHapticEnabled = 'haptic_enabled';
  static const String keyDarkModeEnabled = 'dark_mode_enabled';
  static const String keyAutoBackupEnabled = 'auto_backup_enabled';
  static const String keyOfflineModeEnabled = 'offline_mode_enabled';
  static const String keyPrinterEnabled = 'printer_enabled';
  static const String keyBarcodeScannerEnabled = 'barcode_scanner_enabled';
  static const String keyLanguage = 'language';
  static const String keyCurrency = 'currency';
  static const String keyPrinter = 'printer';
  static const String keyLastBackup = 'last_backup';
  // Tax settings
  static const String keyTaxEnabled = 'tax_enabled';
  static const String keyTaxRate = 'tax_rate';
  static const String keyTaxInclusive = 'tax_inclusive';
  // Custom QR code setting
  static const String keyCustomQRCodeUrl = 'custom_qr_code_url';
  // UI scale setting (preset: 'small', 'normal', 'large', 'extra_large')
  static const String keyUIScale = 'ui_scale';

  /// Validates and sanitizes setting key to prevent path injection
  /// Only allows alphanumeric characters, underscores, and hyphens
  static String _sanitizeSettingKey(String key) {
    if (key.isEmpty) {
      throw ArgumentError('Setting key cannot be empty');
    }
    // Only allow alphanumeric, underscore, and hyphen
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(key)) {
      throw ArgumentError('Invalid setting key format. Only alphanumeric characters, underscores, and hyphens are allowed.');
    }
    return key;
  }

  /// Get SharedPreferences instance
  static Future<SharedPreferences> get _prefs async {
    return await SharedPreferences.getInstance();
  }

  /// Get setting value from local storage
  static Future<T?> getLocalSetting<T>(String key) async {
    final sanitizedKey = _sanitizeSettingKey(key);
    final prefs = await _prefs;
    if (T == bool) {
      return prefs.getBool('$_prefsKeyPrefix$sanitizedKey') as T?;
    } else if (T == String) {
      return prefs.getString('$_prefsKeyPrefix$sanitizedKey') as T?;
    } else if (T == int) {
      return prefs.getInt('$_prefsKeyPrefix$sanitizedKey') as T?;
    } else if (T == double) {
      return prefs.getDouble('$_prefsKeyPrefix$sanitizedKey') as T?;
    }
    return null;
  }

  /// Set setting value in local storage
  static Future<bool> setLocalSetting<T>(String key, T value) async {
    final sanitizedKey = _sanitizeSettingKey(key);
    final prefs = await _prefs;
    if (value is bool) {
      return await prefs.setBool('$_prefsKeyPrefix$sanitizedKey', value);
    } else if (value is String) {
      return await prefs.setString('$_prefsKeyPrefix$sanitizedKey', value);
    } else if (value is int) {
      return await prefs.setInt('$_prefsKeyPrefix$sanitizedKey', value);
    } else if (value is double) {
      return await prefs.setDouble('$_prefsKeyPrefix$sanitizedKey', value);
    }
    return false;
  }

  /// Get setting value from Firebase
  static Future<T?> getFirebaseSetting<T>(String key) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      debugPrint('Error getting Firebase setting: User not authenticated [DIAG: user_not_authenticated]');
      return null;
    }

    try {
      final sanitizedKey = _sanitizeSettingKey(key);
      final ref = _database.ref('users/$userId/settings/$sanitizedKey');
      final snapshot = await ref.get();
      
      if (!snapshot.exists) {
        // Setting not found is normal - will use default value
        // Only log in verbose mode if needed
        return null;
      }
      
      final value = snapshot.value;
      return value as T?;
    } catch (e) {
      final errorString = e.toString();
      debugPrint('Error getting Firebase setting "$key": $e [DIAG: ${errorString.contains('permission-denied') ? 'permission_denied' : errorString.contains('network') ? 'network_error' : 'unknown_error'}]');
      // Don't throw - return null to allow fallback to local storage
      return null;
    }
  }

  /// Set setting value in Firebase
  static Future<void> setFirebaseSetting<T>(String key, T value) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User must be logged in [DIAG: user_not_authenticated]');
    }

    try {
      final sanitizedKey = _sanitizeSettingKey(key);
      final ref = _database.ref('users/$userId/settings/$sanitizedKey');
      await ref.set(value);
    } catch (e) {
      final errorString = e.toString();
      final diagCode = errorString.contains('permission-denied') 
          ? 'permission_denied' 
          : errorString.contains('network') 
              ? 'network_error' 
              : 'unknown_error';
      throw Exception('Error setting Firebase setting "$key": $e [DIAG: $diagCode]');
    }
  }

  /// Get setting with fallback (Firebase -> Local -> Default)
  static Future<T> getSetting<T>(String key, T defaultValue) async {
    // Try Firebase first
    final firebaseValue = await getFirebaseSetting<T>(key);
    if (firebaseValue != null) {
      // Sync to local
      await setLocalSetting(key, firebaseValue);
      return firebaseValue;
    }

    // Try local storage
    final localValue = await getLocalSetting<T>(key);
    if (localValue != null) {
      return localValue;
    }

    // Return default
    return defaultValue;
  }

  /// Set setting (both Firebase and Local)
  static Future<void> setSetting<T>(String key, T value) async {
    // Set in local storage first (for offline mode)
    await setLocalSetting(key, value);

    // Set in Firebase if online
    try {
      await setFirebaseSetting(key, value);
    } catch (e) {
      // If Firebase fails, local storage still has the value
      debugPrint('Error syncing to Firebase: $e');
    }
  }

  /// Sync local settings to Firebase
  static Future<void> syncToFirebase() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final prefs = await _prefs;
    final allKeys = prefs.getKeys().where((key) => key.startsWith(_prefsKeyPrefix));

    try {
      final updates = <String, dynamic>{};
      for (final key in allKeys) {
        final settingKey = key.substring(_prefsKeyPrefix.length);
        try {
          final sanitizedKey = _sanitizeSettingKey(settingKey);
          final value = prefs.get(key);
          if (value != null) {
            updates['users/$userId/settings/$sanitizedKey'] = value;
          }
        } catch (e) {
          // Skip invalid keys during sync
          debugPrint('Skipping invalid setting key during sync: $settingKey');
        }
      }

      if (updates.isNotEmpty) {
        await _database.ref().update(updates);
      }
    } catch (e) {
      debugPrint('Error syncing to Firebase: $e');
    }
  }

  /// Sync Firebase settings to local
  static Future<void> syncFromFirebase() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      debugPrint('Cannot sync from Firebase: User not authenticated [DIAG: user_not_authenticated]');
      return;
    }

    try {
      final ref = _database.ref('users/$userId/settings');
      final snapshot = await ref.get();

      if (!snapshot.exists) {
        debugPrint('No Firebase settings found for user [DIAG: no_settings_found]');
        return;
      }

      final data = snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) {
        debugPrint('Firebase settings data is null [DIAG: null_settings_data]');
        return;
      }

      final prefs = await _prefs;
      for (final entry in data.entries) {
        final key = entry.key as String;
        try {
          final sanitizedKey = _sanitizeSettingKey(key);
          final value = entry.value;
          
          if (value is bool) {
            await prefs.setBool('$_prefsKeyPrefix$sanitizedKey', value);
          } else if (value is String) {
            await prefs.setString('$_prefsKeyPrefix$sanitizedKey', value);
          } else if (value is int) {
            await prefs.setInt('$_prefsKeyPrefix$sanitizedKey', value);
          } else if (value is double) {
            await prefs.setDouble('$_prefsKeyPrefix$sanitizedKey', value);
          }
        } catch (e) {
          // Skip invalid keys during sync
          debugPrint('Skipping invalid setting key during sync: $key [DIAG: invalid_key]');
        }
      }
    } catch (e) {
      final errorString = e.toString();
      final diagCode = errorString.contains('permission-denied') 
          ? 'permission_denied' 
          : errorString.contains('network') 
              ? 'network_error' 
              : 'unknown_error';
      debugPrint('Error syncing from Firebase: $e [DIAG: $diagCode]');
      // Don't throw - allow app to continue with local settings
    }
  }

  /// Backup all data to Firebase
  static Future<void> performBackup() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User must be logged in');

    try {
      // Get all local data
      final prefs = await _prefs;
      final backupData = <String, dynamic>{
        'timestamp': DateTime.now().toIso8601String(),
        'settings': {},
      };

      // Backup settings
      final allKeys = prefs.getKeys().where((key) => key.startsWith(_prefsKeyPrefix));
      for (final key in allKeys) {
        final settingKey = key.substring(_prefsKeyPrefix.length);
        try {
          final sanitizedKey = _sanitizeSettingKey(settingKey);
          final value = prefs.get(key);
          if (value != null) {
            backupData['settings']![sanitizedKey] = value;
          }
        } catch (e) {
          // Skip invalid keys during backup
          debugPrint('Skipping invalid setting key during backup: $settingKey');
        }
      }

      // Save backup to Firebase
      final ref = _database.ref('backups/$userId/${DateTime.now().millisecondsSinceEpoch}');
      await ref.set(backupData);

      // Update last backup time
      await setSetting(keyLastBackup, DateTime.now().toIso8601String());
    } catch (e) {
      throw Exception('Error performing backup: $e');
    }
  }

  /// Check if offline mode is enabled
  static Future<bool> isOfflineMode() async {
    return await getSetting(keyOfflineModeEnabled, false);
  }
}

