import 'package:flutter/services.dart';

/// Utility class for consistent haptic feedback across the app
class HapticHelper {
  /// Light impact haptic feedback
  /// Use for subtle interactions like button taps, selections
  static void lightImpact() {
    HapticFeedback.lightImpact();
  }

  /// Medium impact haptic feedback
  /// Use for more significant actions like confirmations
  static void mediumImpact() {
    HapticFeedback.mediumImpact();
  }

  /// Heavy impact haptic feedback
  /// Use for important actions like deletions, critical confirmations
  static void heavyImpact() {
    HapticFeedback.heavyImpact();
  }

  /// Selection change haptic feedback
  /// Use for selection changes in pickers, switches, etc.
  static void selectionClick() {
    HapticFeedback.selectionClick();
  }

  /// Vibrate haptic feedback
  /// Use for notifications or alerts
  static void vibrate() {
    HapticFeedback.vibrate();
  }
}

