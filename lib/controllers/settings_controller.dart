import 'package:flutter/foundation.dart';
import '../services/settings_service.dart';
import '../services/auth_service.dart';

class SettingsController extends ChangeNotifier {
  // Settings state
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _hapticEnabled = true;
  bool _darkModeEnabled = false;
  bool _autoBackupEnabled = true;
  bool _offlineModeEnabled = false;
  bool _printerEnabled = true;
  bool _barcodeScannerEnabled = true;
  
  // Tax settings
  bool _taxEnabled = true;
  double _taxRate = 0.11; // 11% default (PPN Indonesia)
  bool _taxInclusive = false; // Tax exclusive by default
  
  // Custom QR code
  String? _customQRCodeUrl;
  
  String _selectedLanguage = 'Bahasa Indonesia';
  String _selectedCurrency = 'IDR (Rupiah)';
  String _selectedPrinter = 'Default Printer';
  
  bool _isLoading = true;
  String? _errorMessage;

  // Options
  final List<String> languages = ['Bahasa Indonesia', 'English', '中文'];
  final List<String> currencies = ['IDR (Rupiah)', 'USD (Dollar)', 'EUR (Euro)'];
  final List<String> printers = ['Default Printer', 'Thermal Printer', 'Bluetooth Printer'];

  // Getters
  bool get notificationsEnabled => _notificationsEnabled;
  bool get soundEnabled => _soundEnabled;
  bool get hapticEnabled => _hapticEnabled;
  bool get darkModeEnabled => _darkModeEnabled;
  bool get autoBackupEnabled => _autoBackupEnabled;
  bool get offlineModeEnabled => _offlineModeEnabled;
  bool get printerEnabled => _printerEnabled;
  bool get barcodeScannerEnabled => _barcodeScannerEnabled;
  bool get taxEnabled => _taxEnabled;
  double get taxRate => _taxRate;
  bool get taxInclusive => _taxInclusive;
  String? get customQRCodeUrl => _customQRCodeUrl;
  String get selectedLanguage => _selectedLanguage;
  String get selectedCurrency => _selectedCurrency;
  String get selectedPrinter => _selectedPrinter;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> initialize() async {
    await loadSettings();
  }

  Future<void> loadSettings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Load from settings service
      _notificationsEnabled = await SettingsService.getSetting(
        SettingsService.keyNotificationsEnabled,
        true,
      );
      _soundEnabled = await SettingsService.getSetting(
        SettingsService.keySoundEnabled,
        true,
      );
      _hapticEnabled = await SettingsService.getSetting(
        SettingsService.keyHapticEnabled,
        true,
      );
      _darkModeEnabled = await SettingsService.getSetting(
        SettingsService.keyDarkModeEnabled,
        false,
      );
      _autoBackupEnabled = await SettingsService.getSetting(
        SettingsService.keyAutoBackupEnabled,
        true,
      );
      _offlineModeEnabled = await SettingsService.getSetting(
        SettingsService.keyOfflineModeEnabled,
        false,
      );
      _printerEnabled = await SettingsService.getSetting(
        SettingsService.keyPrinterEnabled,
        true,
      );
      _barcodeScannerEnabled = await SettingsService.getSetting(
        SettingsService.keyBarcodeScannerEnabled,
        true,
      );
      _selectedLanguage = await SettingsService.getSetting(
        SettingsService.keyLanguage,
        'Bahasa Indonesia',
      );
      _selectedCurrency = await SettingsService.getSetting(
        SettingsService.keyCurrency,
        'IDR (Rupiah)',
      );
      _selectedPrinter = await SettingsService.getSetting(
        SettingsService.keyPrinter,
        'Default Printer',
      );
      _taxEnabled = await SettingsService.getSetting(
        SettingsService.keyTaxEnabled,
        true,
      );
      _taxRate = await SettingsService.getSetting(
        SettingsService.keyTaxRate,
        0.11,
      );
      _taxInclusive = await SettingsService.getSetting(
        SettingsService.keyTaxInclusive,
        false,
      );
      final qrCodeUrl = await SettingsService.getSetting<String>(
        SettingsService.keyCustomQRCodeUrl,
        '',
      );
      _customQRCodeUrl = qrCodeUrl.isEmpty ? null : qrCodeUrl;

      // Sync from Firebase if online (only once on initial load)
      if (!_offlineModeEnabled) {
        try {
          await SettingsService.syncFromFirebase();
          // Reload settings after sync
          _notificationsEnabled = await SettingsService.getSetting(
            SettingsService.keyNotificationsEnabled,
            true,
          );
          _soundEnabled = await SettingsService.getSetting(
            SettingsService.keySoundEnabled,
            true,
          );
          _hapticEnabled = await SettingsService.getSetting(
            SettingsService.keyHapticEnabled,
            true,
          );
          _darkModeEnabled = await SettingsService.getSetting(
            SettingsService.keyDarkModeEnabled,
            false,
          );
          _autoBackupEnabled = await SettingsService.getSetting(
            SettingsService.keyAutoBackupEnabled,
            true,
          );
          _offlineModeEnabled = await SettingsService.getSetting(
            SettingsService.keyOfflineModeEnabled,
            false,
          );
          _printerEnabled = await SettingsService.getSetting(
            SettingsService.keyPrinterEnabled,
            true,
          );
          _barcodeScannerEnabled = await SettingsService.getSetting(
            SettingsService.keyBarcodeScannerEnabled,
            true,
          );
          _selectedLanguage = await SettingsService.getSetting(
            SettingsService.keyLanguage,
            'Bahasa Indonesia',
          );
          _selectedCurrency = await SettingsService.getSetting(
            SettingsService.keyCurrency,
            'IDR (Rupiah)',
          );
          _selectedPrinter = await SettingsService.getSetting(
            SettingsService.keyPrinter,
            'Default Printer',
          );
          _taxEnabled = await SettingsService.getSetting(
            SettingsService.keyTaxEnabled,
            true,
          );
          _taxRate = await SettingsService.getSetting(
            SettingsService.keyTaxRate,
            0.11,
          );
          _taxInclusive = await SettingsService.getSetting(
            SettingsService.keyTaxInclusive,
            false,
          );
          final qrCodeUrlAfterSync = await SettingsService.getSetting<String>(
            SettingsService.keyCustomQRCodeUrl,
            '',
          );
          _customQRCodeUrl = qrCodeUrlAfterSync.isEmpty ? null : qrCodeUrlAfterSync;
        } catch (e) {
          debugPrint('Error syncing from Firebase: $e');
        }
      }
    } catch (e) {
      _errorMessage = 'Gagal memuat pengaturan: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateSetting<T>(String key, T value) async {
    try {
      await SettingsService.setSetting(key, value);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Gagal memperbarui pengaturan: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    notifyListeners();
    await updateSetting(SettingsService.keyNotificationsEnabled, value);
  }

  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    notifyListeners();
    await updateSetting(SettingsService.keySoundEnabled, value);
  }

  Future<void> setHapticEnabled(bool value) async {
    _hapticEnabled = value;
    notifyListeners();
    await updateSetting(SettingsService.keyHapticEnabled, value);
  }

  Future<void> setDarkModeEnabled(bool value) async {
    _darkModeEnabled = value;
    notifyListeners();
    await updateSetting(SettingsService.keyDarkModeEnabled, value);
  }

  Future<void> setAutoBackupEnabled(bool value) async {
    _autoBackupEnabled = value;
    notifyListeners();
    await updateSetting(SettingsService.keyAutoBackupEnabled, value);
  }

  Future<void> setOfflineModeEnabled(bool value) async {
    _offlineModeEnabled = value;
    notifyListeners();
    await updateSetting(SettingsService.keyOfflineModeEnabled, value);
  }

  Future<void> setPrinterEnabled(bool value) async {
    _printerEnabled = value;
    notifyListeners();
    await updateSetting(SettingsService.keyPrinterEnabled, value);
  }

  Future<void> setBarcodeScannerEnabled(bool value) async {
    _barcodeScannerEnabled = value;
    notifyListeners();
    await updateSetting(SettingsService.keyBarcodeScannerEnabled, value);
  }

  Future<void> setTaxEnabled(bool value) async {
    _taxEnabled = value;
    notifyListeners();
    await updateSetting(SettingsService.keyTaxEnabled, value);
  }

  Future<void> setTaxRate(double value) async {
    _taxRate = value.clamp(0.0, 1.0); // Ensure between 0% and 100%
    notifyListeners();
    await updateSetting(SettingsService.keyTaxRate, _taxRate);
  }

  Future<void> setTaxInclusive(bool value) async {
    _taxInclusive = value;
    notifyListeners();
    await updateSetting(SettingsService.keyTaxInclusive, value);
  }

  Future<void> setLanguage(String value) async {
    _selectedLanguage = value;
    notifyListeners();
    await updateSetting(SettingsService.keyLanguage, value);
  }

  Future<void> setCurrency(String value) async {
    _selectedCurrency = value;
    notifyListeners();
    await updateSetting(SettingsService.keyCurrency, value);
  }

  Future<void> setPrinter(String value) async {
    _selectedPrinter = value;
    notifyListeners();
    await updateSetting(SettingsService.keyPrinter, value);
  }

  Future<void> setCustomQRCodeUrl(String? url) async {
    _customQRCodeUrl = url;
    notifyListeners();
    // Use empty string to represent null in settings
    await updateSetting(SettingsService.keyCustomQRCodeUrl, url ?? '');
  }

  Future<void> performBackup() async {
    try {
      await SettingsService.performBackup();
    } catch (e) {
      _errorMessage = 'Gagal melakukan backup: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> syncToFirebase() async {
    try {
      await SettingsService.syncToFirebase();
    } catch (e) {
      _errorMessage = 'Gagal menyinkronkan: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await AuthService.signOut();
    } catch (e) {
      _errorMessage = 'Gagal keluar: $e';
      notifyListeners();
      rethrow;
    }
  }

  void resetToDefaults() {
    _notificationsEnabled = true;
    _soundEnabled = true;
    _hapticEnabled = true;
    _darkModeEnabled = false;
    _autoBackupEnabled = true;
    _offlineModeEnabled = false;
    _printerEnabled = true;
    _barcodeScannerEnabled = true;
    _taxEnabled = true;
    _taxRate = 0.11;
    _taxInclusive = false;
    _selectedLanguage = 'Bahasa Indonesia';
    _selectedCurrency = 'IDR (Rupiah)';
    _selectedPrinter = 'Default Printer';
    notifyListeners();
  }
}

