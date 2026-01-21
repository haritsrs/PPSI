import 'package:flutter/services.dart';

/// Text input formatter for Indonesian Rupiah currency
/// Formats numbers with periods every 1000 (e.g., 18000 -> 18.000)
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove all non-digit characters
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    // Format with periods every 1000
    String formatted = _formatWithPeriods(digitsOnly);

    // Calculate the new cursor position
    int selectionIndex = formatted.length;
    if (oldValue.text.isNotEmpty) {
      // Try to maintain cursor position relative to the end
      final oldDigits = oldValue.text.replaceAll(RegExp(r'[^\d]'), '');
      final newDigits = digitsOnly;
      
      if (newDigits.length < oldDigits.length) {
        // Character was deleted
        selectionIndex = formatted.length;
      } else {
        // Character was added
        selectionIndex = formatted.length;
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }

  String _formatWithPeriods(String value) {
    if (value.isEmpty) return '';
    
    // Reverse the string to add periods from right to left
    String reversed = value.split('').reversed.join();
    String formatted = '';
    
    for (int i = 0; i < reversed.length; i++) {
      if (i > 0 && i % 3 == 0) {
        formatted += '.';
      }
      formatted += reversed[i];
    }
    
    // Reverse back
    return formatted.split('').reversed.join();
  }

  /// Parse formatted currency string to double
  static double? parseFormattedCurrency(String formatted) {
    if (formatted.isEmpty) return null;
    final digitsOnly = formatted.replaceAll(RegExp(r'[^\d]'), '');
    return double.tryParse(digitsOnly);
  }
}


