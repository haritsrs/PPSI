import 'dart:typed_data';
import 'dart:convert';

/// Text alignment for ESC/POS commands
enum TextAlign {
  left,
  center,
  right,
}

/// ESC/POS command utilities for thermal printers
/// Compatible with VSC TM 58V and other ESC/POS printers
class PrinterCommands {
  // Paper width for 58mm thermal printers (384 pixels at 203 DPI)
  static const int paperWidth = 384;
  static const int paperWidthMm = 58;

  /// Initialize printer
  static List<int> init() {
    return [0x1B, 0x40]; // ESC @ (Reset printer)
  }

  /// Reset printer
  static List<int> reset() {
    return [0x1B, 0x40]; // ESC @
  }

  /// Feed paper
  static List<int> feed([int lines = 1]) {
    return List.filled(lines, 0x0A); // LF
  }

  /// Cut paper (partial cut)
  static List<int> cut() {
    return [0x1D, 0x56, 0x41, 0x00]; // GS V A 0
  }

  /// Full cut paper
  static List<int> fullCut() {
    return [0x1D, 0x56, 0x00]; // GS V 0
  }

  /// Set text alignment
  static List<int> align(TextAlign align) {
    switch (align) {
      case TextAlign.left:
        return [0x1B, 0x61, 0x00]; // ESC a 0
      case TextAlign.center:
        return [0x1B, 0x61, 0x01]; // ESC a 1
      case TextAlign.right:
        return [0x1B, 0x61, 0x02]; // ESC a 2
    }
  }

  /// Set text size
  static List<int> textSize({
    int width = 1,
    int height = 1,
  }) {
    if (width < 1 || width > 8 || height < 1 || height > 8) {
      throw ArgumentError('Text size must be between 1 and 8');
    }
    // ESC ! n (n = (width-1) | ((height-1) << 4))
    final n = (width - 1) | ((height - 1) << 4);
    return [0x1B, 0x21, n];
  }

  /// Set bold text
  static List<int> bold(bool enabled) {
    return [0x1B, 0x45, enabled ? 0x01 : 0x00]; // ESC E
  }

  /// Set underline
  static List<int> underline(bool enabled) {
    return [0x1B, 0x2D, enabled ? 0x01 : 0x00]; // ESC -
  }

  /// Set reverse (white text on black background)
  static List<int> reverse(bool enabled) {
    return [0x1D, 0x42, enabled ? 0x01 : 0x00]; // GS B
  }

  /// Print text (UTF-8 encoded)
  static List<int> text(String text, {String charset = 'UTF-8'}) {
    // Convert string to bytes (UTF-8 encoding)
    // For ESC/POS, we'll use UTF-8 and let the printer handle it
    // Some printers may need specific encoding, but UTF-8 is most common
    // Use UTF-8 encoding for proper character support
    return utf8.encode(text);
  }

  /// Print text with encoding
  static List<int> textEncoded(String textValue) {
    return text(textValue, charset: 'UTF-8');
  }

  /// Print line (text + newline)
  static List<int> textLine(String textValue, {String charset = 'CP1252'}) {
    return [...text(textValue, charset: charset), ...feed()];
  }

  /// Print empty line
  static List<int> emptyLines(int count) {
    return feed(count);
  }

  /// Print horizontal line (divider)
  static List<int> divider({String character = '-', int? width}) {
    final lineWidth = width ?? paperWidth;
    final charCount = (lineWidth / 8).floor(); // Approximate character count
    final line = character * charCount;
    return textLine(line);
  }

  /// Print double line divider
  static List<int> doubleDivider() {
    return divider(character: '=');
  }

  /// Print QR code
  static List<int> qrCode(
    String data, {
    int size = 6,
    int errorCorrectionLevel = 2,
    int model = 2,
  }) {
    // Model selection (GS (k) pL pH cn fn n)
    // Model 2 is standard
    final List<int> commands = [];
    
    // Set QR code model
    commands.addAll([0x1D, 0x28, 0x6B, 0x04, 0x00, 0x31, 0x41, model, 0x00]);
    
    // Set QR code size (1-8, default 6)
    final qrSize = size.clamp(1, 8);
    commands.addAll([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x43, qrSize]);
    
    // Set error correction level (0-3, default 2 = M)
    final ecLevel = errorCorrectionLevel.clamp(0, 3);
    commands.addAll([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x45, ecLevel]);
    
    // Store QR code data
    final dataBytes = Uint8List.fromList(data.codeUnits);
    final p1 = dataBytes.length & 0xFF;
    final p2 = (dataBytes.length >> 8) & 0xFF;
    commands.addAll([0x1D, 0x28, 0x6B, p1, p2, 0x31, 0x50, 0x30]);
    commands.addAll(dataBytes);
    
    // Print QR code
    commands.addAll([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x51, 0x30]);
    
    return commands;
  }

  /// Print image (bitmap)
  /// Image should be resized to paperWidth (384px) before calling this
  static List<int> image(Uint8List imageBytes, {int width = paperWidth}) {
    // This is a simplified version - full image printing requires
    // proper bitmap conversion and ESC/POS raster image commands
    // For now, return empty - will be implemented in receipt_builder
    return [];
  }

  /// Combine multiple command lists
  static List<int> combine(List<List<int>> commands) {
    return commands.expand((cmd) => cmd).toList();
  }

  /// Build complete receipt with commands
  static List<int> buildReceipt(List<List<int>> sections) {
    final commands = <int>[];
    
    // Initialize printer
    commands.addAll(init());
    
    // Add all sections
    for (final section in sections) {
      commands.addAll(section);
    }
    
    // Feed and cut
    commands.addAll(feed(3));
    commands.addAll(cut());
    
    return commands;
  }
}

