import 'package:flutter/material.dart';
import '../widgets/error_detail_dialog.dart';

/// Utility class for displaying consistent SnackBar messages across the app
class SnackbarHelper {
  /// Show a success message
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: duration ?? const Duration(seconds: 3),
      ),
    );
  }

  /// Show an error message (with optional detailed dialog for long errors)
  static void showError(
    BuildContext context,
    String message, {
    Duration? duration,
    String? details,
    bool forceDialog = false,
  }) {
    if (!context.mounted) return;
    
    // Show detailed dialog for long messages or when forced
    final isLongError = message.length > 100 || (details != null && details.isNotEmpty);
    if (forceDialog || isLongError) {
      ErrorDetailDialog.show(
        context,
        title: 'Error Detail',
        message: message,
        details: details,
      );
      return;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: duration ?? const Duration(seconds: 4),
        action: isLongError
            ? SnackBarAction(
                label: 'Detail',
                textColor: Colors.white,
                onPressed: () {
                  ErrorDetailDialog.show(
                    context,
                    title: 'Error Detail',
                    message: message,
                    details: details,
                  );
                },
              )
            : null,
      ),
    );
  }

  /// Show an info/warning message
  static void showInfo(
    BuildContext context,
    String message, {
    Duration? duration,
    Color? backgroundColor,
  }) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor ?? Colors.orange,
        behavior: SnackBarBehavior.floating,
        duration: duration ?? const Duration(seconds: 3),
      ),
    );
  }
}

