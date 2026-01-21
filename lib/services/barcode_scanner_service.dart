import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/product_model.dart';

/// Service for handling barcode scanner input
/// Manages focus nodes, keyboard events, and barcode detection
class BarcodeScannerService {
  final FocusNode barcodeFocusNode;
  final FocusNode? searchFocusNode;
  final FocusNode? testBarcodeFocusNode;
  final TextEditingController? searchController;
  final TextEditingController? testBarcodeController;

  // Callbacks
  final Function(String) onBarcodeDetected;
  final VoidCallback? onRefocusNeeded;
  final VoidCallback? onHapticFeedback;

  // State
  bool _enabled = true;
  bool _testModeEnabled = false;
  DateTime? _lastSearchInputTime;
  String _lastSearchValue = '';
  Timer? _searchBarcodeTimer;
  Timer? _testBarcodeProcessTimer;

  BarcodeScannerService({
    required this.onBarcodeDetected,
    this.onRefocusNeeded,
    this.onHapticFeedback,
    this.searchFocusNode,
    this.testBarcodeFocusNode,
    this.searchController,
    this.testBarcodeController,
  }) : barcodeFocusNode = FocusNode(skipTraversal: true, debugLabel: 'barcodeScanner') {
    _setupListeners();
  }

  bool get enabled => _enabled;
  bool get testModeEnabled => _testModeEnabled;

  void setEnabled(bool enabled) {
    _enabled = enabled;
    if (!enabled) {
      barcodeFocusNode.unfocus();
    } else {
      refocus();
    }
  }

  void setTestMode(bool enabled) {
    _testModeEnabled = enabled;
    if (enabled) {
      barcodeFocusNode.unfocus();
      refocusTestScanner();
    } else {
      testBarcodeFocusNode?.unfocus();
      refocus();
    }
  }

  void _setupListeners() {
    // Search focus listener - refocus barcode scanner when search loses focus
    searchFocusNode?.addListener(() {
      if (!searchFocusNode!.hasFocus && 
          !_testModeEnabled && 
          _enabled) {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (!_testModeEnabled && _enabled) {
            refocus();
          }
        });
      }
    });

    // Barcode focus listener - maintain focus automatically
    barcodeFocusNode.addListener(() {
      if (!barcodeFocusNode.hasFocus && 
          !_testModeEnabled && 
          _enabled &&
          !(searchFocusNode?.hasFocus ?? false) &&
          !(testBarcodeFocusNode?.hasFocus ?? false)) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (!_testModeEnabled && 
              _enabled && 
              !(searchFocusNode?.hasFocus ?? false) &&
              !(testBarcodeFocusNode?.hasFocus ?? false)) {
            barcodeFocusNode.requestFocus();
          }
        });
      }
    });

    // Search controller listener - detect barcode scanner input in search field
    searchController?.addListener(() {
      if (_testModeEnabled) return;

      final currentValue = searchController!.text;
      final now = DateTime.now();

      if (searchFocusNode?.hasFocus ?? false) {
        if (_lastSearchInputTime != null) {
          final timeSinceLastInput = now.difference(_lastSearchInputTime!);
          // If characters are coming in faster than 50ms apart, it's likely a barcode scanner
          if (timeSinceLastInput < const Duration(milliseconds: 50) &&
              currentValue.length > _lastSearchValue.length) {
            _searchBarcodeTimer?.cancel();

            // Wait for input to settle (barcode scanners send all chars quickly)
            _searchBarcodeTimer = Timer(const Duration(milliseconds: 500), () {
              final fullBarcode = searchController!.text.trim();
              if (fullBarcode.isNotEmpty && fullBarcode.length >= 3) {
                onBarcodeDetected(fullBarcode);
                onHapticFeedback?.call();
                searchController!.clear();
                searchFocusNode?.unfocus();
                refocus();
              }
            });
          }
        }
      }

      _lastSearchInputTime = now;
      _lastSearchValue = currentValue;
    });

    // Test barcode controller listener
    testBarcodeController?.addListener(() {
      if (!_testModeEnabled) return;

      final currentValue = testBarcodeController!.text;

      _testBarcodeProcessTimer?.cancel();

      if (currentValue.isEmpty) {
        // Field cleared - notify to clear buffer
        onBarcodeDetected(''); // Empty string signals clear
        return;
      }

      // Wait for input to settle
      _testBarcodeProcessTimer = Timer(const Duration(milliseconds: 300), () {
        if (_testModeEnabled) {
          final fullBarcode = testBarcodeController!.text.trim();
          if (fullBarcode.isNotEmpty && fullBarcode.length >= 3) {
            onBarcodeDetected(fullBarcode);
            onHapticFeedback?.call();
            testBarcodeController!.clear();
            refocusTestScanner();
          }
        }
      });
    });
  }

  /// Handle raw keyboard events for barcode scanning
  void handleRawKeyEvent(RawKeyEvent event, {
    required String Function() getBarcodeBuffer,
    required void Function(String) setBarcodeBuffer,
    required void Function() clearBarcodeBuffer,
    required void Function() handleBackspace,
    required Product? Function() handleEnter,
    required bool Function() checkBuffer,
  }) {
    if (event is! RawKeyDownEvent) return;
    if (!_enabled) return;

    final logicalKey = event.logicalKey;

    // If search field has focus, only handle Enter key
    if (searchFocusNode?.hasFocus ?? false) {
      if (logicalKey == LogicalKeyboardKey.enter ||
          logicalKey == LogicalKeyboardKey.numpadEnter) {
        if (getBarcodeBuffer().isNotEmpty) {
          final product = handleEnter();
          if (product != null) {
            onHapticFeedback?.call();
            searchController?.clear();
            searchFocusNode?.unfocus();
            if (_enabled) {
              refocus();
            }
          }
        }
      }
      return;
    }

    // Handle Enter key - complete barcode scan
    if (logicalKey == LogicalKeyboardKey.enter ||
        logicalKey == LogicalKeyboardKey.numpadEnter) {
      if (getBarcodeBuffer().isNotEmpty) {
        final product = handleEnter();
        if (product != null) {
          onHapticFeedback?.call();
        }
      }
      if (_enabled) {
        refocus();
      }
      return;
    }

    // Handle backspace
    if (logicalKey == LogicalKeyboardKey.backspace) {
      handleBackspace();
      return;
    }

    // Handle character input
    final character = event.character;
    if (character != null && character.isNotEmpty) {
      final codeUnit = character.codeUnitAt(0);
      // Accept printable characters (32-126), excluding DEL (127)
      if (codeUnit >= 32 && codeUnit != 127) {
        setBarcodeBuffer(character);
        // Wait for more characters (barcode scanners send them rapidly)
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_enabled) {
            final found = checkBuffer();
            if (found) {
              onHapticFeedback?.call();
            }
            if (_enabled) {
              refocus();
            }
          }
        });
      }
    }
  }

  /// Refocus barcode scanner
  void refocus() {
    if (!_enabled || _testModeEnabled) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_testModeEnabled && 
          _enabled && 
          !(searchFocusNode?.hasFocus ?? false)) {
        Future.delayed(const Duration(milliseconds: 50), () {
          if (!_testModeEnabled && 
              _enabled && 
              !(searchFocusNode?.hasFocus ?? false)) {
            barcodeFocusNode.requestFocus();
          }
        });
      }
    });
  }

  /// Refocus test scanner
  void refocusTestScanner() {
    if (!_testModeEnabled) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_testModeEnabled) {
        testBarcodeFocusNode?.requestFocus();
      }
    });
  }

  /// Initialize focus after widget build
  void initializeFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_testModeEnabled) {
        refocusTestScanner();
      } else if (_enabled) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (!_testModeEnabled && _enabled) {
            barcodeFocusNode.requestFocus();
          }
        });
      }
    });
  }

  /// Unfocus scanner (e.g., when opening dialogs)
  void unfocus() {
    barcodeFocusNode.unfocus();
  }

  /// Dispose resources
  void dispose() {
    _searchBarcodeTimer?.cancel();
    _testBarcodeProcessTimer?.cancel();
    barcodeFocusNode.dispose();
    // Note: Don't dispose searchFocusNode or testBarcodeFocusNode as they may be managed elsewhere
  }
}



