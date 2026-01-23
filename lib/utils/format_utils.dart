import '../services/settings_service.dart';

class FormatUtils {
  // Cache for currency to avoid repeated async calls
  static String? _cachedCurrency;

  static String formatCurrency(num value) {
    // Use cached currency if available, otherwise default to IDR
    final currency = _cachedCurrency ?? 'IDR (Rupiah)';
    return _formatCurrencyWithType(value, currency);
  }

  static Future<String> formatCurrencyAsync(num value) async {
    // Load currency from settings if not cached
    _cachedCurrency ??= await SettingsService.getSetting(
      SettingsService.keyCurrency,
      'IDR (Rupiah)',
    );
    return _formatCurrencyWithType(value, _cachedCurrency!);
  }

  static String _formatCurrencyWithType(num value, String currencyType) {
    // Determine currency symbol and format
    if (currencyType.startsWith('USD')) {
      // USD: $1,234.56
      return '\$${value.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}'; 
    } else if (currencyType.startsWith('EUR')) {
      // EUR: €1.234,56 (European format)
      final parts = value.toStringAsFixed(2).split('.');
      final intPart = parts[0].replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
      return '€$intPart,${parts[1]}';
    } else {
      // IDR (Rupiah) - default: Rp 1.234 (no decimals)
      return 'Rp ${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
    }
  }

  // Call this when currency changes to update cache
  static void updateCurrencyCache(String currency) {
    _cachedCurrency = currency;
  }

  // Clear cache (useful for testing or logout)
  static void clearCache() {
    _cachedCurrency = null;
  }
}
