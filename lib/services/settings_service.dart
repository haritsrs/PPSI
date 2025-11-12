import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsService {
  static const String _prefsKeyPrefix = 'settings_';
  static final FirebaseDatabase _database = FirebaseDatabase.instance;
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

  /// Get SharedPreferences instance
  static Future<SharedPreferences> get _prefs async {
    return await SharedPreferences.getInstance();
  }

  /// Get setting value from local storage
  static Future<T?> getLocalSetting<T>(String key) async {
    final prefs = await _prefs;
    if (T == bool) {
      return prefs.getBool('$_prefsKeyPrefix$key') as T?;
    } else if (T == String) {
      return prefs.getString('$_prefsKeyPrefix$key') as T?;
    } else if (T == int) {
      return prefs.getInt('$_prefsKeyPrefix$key') as T?;
    } else if (T == double) {
      return prefs.getDouble('$_prefsKeyPrefix$key') as T?;
    }
    return null;
  }

  /// Set setting value in local storage
  static Future<bool> setLocalSetting<T>(String key, T value) async {
    final prefs = await _prefs;
    if (value is bool) {
      return await prefs.setBool('$_prefsKeyPrefix$key', value);
    } else if (value is String) {
      return await prefs.setString('$_prefsKeyPrefix$key', value);
    } else if (value is int) {
      return await prefs.setInt('$_prefsKeyPrefix$key', value);
    } else if (value is double) {
      return await prefs.setDouble('$_prefsKeyPrefix$key', value);
    }
    return false;
  }

  /// Get setting value from Firebase
  static Future<T?> getFirebaseSetting<T>(String key) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;

    try {
      final ref = _database.ref('settings/$userId/$key');
      final snapshot = await ref.get();
      
      if (!snapshot.exists) return null;
      
      final value = snapshot.value;
      return value as T?;
    } catch (e) {
      print('Error getting Firebase setting: $e');
      return null;
    }
  }

  /// Set setting value in Firebase
  static Future<void> setFirebaseSetting<T>(String key, T value) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User must be logged in');

    try {
      final ref = _database.ref('settings/$userId/$key');
      await ref.set(value);
    } catch (e) {
      throw Exception('Error setting Firebase setting: $e');
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
      print('Error syncing to Firebase: $e');
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
        final value = prefs.get(key);
        if (value != null) {
          updates['settings/$userId/$settingKey'] = value;
        }
      }

      if (updates.isNotEmpty) {
        await _database.ref().update(updates);
      }
    } catch (e) {
      print('Error syncing to Firebase: $e');
    }
  }

  /// Sync Firebase settings to local
  static Future<void> syncFromFirebase() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final ref = _database.ref('settings/$userId');
      final snapshot = await ref.get();

      if (!snapshot.exists) return;

      final data = snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return;

      final prefs = await _prefs;
      for (final entry in data.entries) {
        final key = entry.key as String;
        final value = entry.value;
        
        if (value is bool) {
          await prefs.setBool('$_prefsKeyPrefix$key', value);
        } else if (value is String) {
          await prefs.setString('$_prefsKeyPrefix$key', value);
        } else if (value is int) {
          await prefs.setInt('$_prefsKeyPrefix$key', value);
        } else if (value is double) {
          await prefs.setDouble('$_prefsKeyPrefix$key', value);
        }
      }
    } catch (e) {
      print('Error syncing from Firebase: $e');
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
        final value = prefs.get(key);
        if (value != null) {
          backupData['settings']![settingKey] = value;
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

