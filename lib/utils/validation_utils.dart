/// Validation utilities for form inputs
class ValidationUtils {
  ValidationUtils._();

  static const String _emailPattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
  static const int _minPasswordLength = 8;
  static const int _maxPasswordLength = 128;

  /// Validates email format
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email tidak boleh kosong';
    }
    if (!RegExp(_emailPattern).hasMatch(value)) {
      return 'Format email tidak valid';
    }
    return null;
  }

  /// Validates password strength
  /// Requires: minimum 8 characters, at least one letter and one number
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    
    if (value.length < _minPasswordLength) {
      return 'Password minimal $_minPasswordLength karakter';
    }
    
    if (value.length > _maxPasswordLength) {
      return 'Password maksimal $_maxPasswordLength karakter';
    }
    
    // Check for at least one letter (uppercase or lowercase)
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(value);
    // Check for at least one number
    final hasNumber = RegExp(r'[0-9]').hasMatch(value);
    
    if (!hasLetter) {
      return 'Password harus mengandung minimal satu huruf';
    }
    
    if (!hasNumber) {
      return 'Password harus mengandung minimal satu angka';
    }
    
    return null;
  }

  /// Validates password for login only (no strength rules)
  /// Allows legacy passwords while keeping basic sanity checks
  static String? validateLoginPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }

    if (value.length > _maxPasswordLength) {
      return 'Password maksimal $_maxPasswordLength karakter';
    }

    return null;
  }

  /// Calculates password strength score (0-4)
  /// 0: Very weak, 1: Weak, 2: Fair, 3: Good, 4: Strong
  static int getPasswordStrength(String password) {
    if (password.isEmpty) return 0;
    
    int score = 0;
    
    // Length check
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    
    // Character variety
    if (RegExp(r'[a-z]').hasMatch(password) && RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[^a-zA-Z0-9]').hasMatch(password)) score++;
    
    // Cap at 4
    return score > 4 ? 4 : score;
  }

  /// Validates non-empty text
  static String? validateRequired(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName tidak boleh kosong';
    }
    return null;
  }

  /// Validates minimum length
  static String? validateMinLength(String? value, int minLength, {String fieldName = 'Field'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName tidak boleh kosong';
    }
    if (value.length < minLength) {
      return '$fieldName minimal $minLength karakter';
    }
    return null;
  }

  /// Validates password confirmation
  static String? validatePasswordConfirmation(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi password tidak boleh kosong';
    }
    if (value != password) {
      return 'Password tidak cocok';
    }
    return null;
  }
}

