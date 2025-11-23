import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:usb_serial/usb_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/printer_commands.dart';
import '../services/receipt_builder.dart';

/// Printer connection type
enum PrinterType {
  usb,
  bluetooth,
}

/// Printer device model
class PrinterDevice {
  final String id;
  final String name;
  final PrinterType type;
  final dynamic device; // USBDevice or BluetoothDevice

  PrinterDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.device,
  });

  @override
  String toString() => '$name (${type == PrinterType.usb ? 'USB' : 'Bluetooth'})';
}

/// Printer service for USB and Bluetooth thermal printers
/// Supports ESC/POS compatible printers (VSC TM 58V, etc.)
/// Singleton pattern to maintain printer connection across widget lifecycles
class PrinterService extends ChangeNotifier {
  static const String _prefsKeySelectedPrinter = 'selected_printer_id';
  static const String _prefsKeyPrinterType = 'selected_printer_type';
  static const String _prefsKeyPrinterName = 'selected_printer_name';
  
  // Singleton instance
  static PrinterService? _instance;
  
  PrinterDevice? _connectedPrinter;
  bool _isConnecting = false;
  bool _isScanning = false;
  String? _errorMessage;
  StreamSubscription? _bluetoothSubscription;
  UsbPort? _usbPort;
  bool _isDisposed = false;

  // Getters
  PrinterDevice? get connectedPrinter => _connectedPrinter;
  bool get isConnected => _connectedPrinter != null;
  bool get isConnecting => _isConnecting;
  bool get isScanning => _isScanning;
  String? get errorMessage => _errorMessage;

  // Private constructor for singleton
  PrinterService._internal() {
    _loadSavedPrinter();
  }

  // Factory constructor returns singleton instance
  factory PrinterService() {
    _instance ??= PrinterService._internal();
    return _instance!;
  }

  /// Load saved printer from preferences
  Future<void> _loadSavedPrinter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final printerId = prefs.getString(_prefsKeySelectedPrinter);
      final printerTypeStr = prefs.getString(_prefsKeyPrinterType);
      final printerName = prefs.getString(_prefsKeyPrinterName);

      if (printerId != null && printerTypeStr != null && printerName != null) {
        final printerType = printerTypeStr == 'usb' ? PrinterType.usb : PrinterType.bluetooth;
        // Note: We can't restore the actual device object, but we can store the info
        // The user will need to reconnect on app startup
        debugPrint('Saved printer found: $printerName ($printerType)');
      }
    } catch (e) {
      debugPrint('Error loading saved printer: $e');
    }
  }

  /// Save printer to preferences
  Future<void> _savePrinter(PrinterDevice printer) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKeySelectedPrinter, printer.id);
      await prefs.setString(_prefsKeyPrinterType, printer.type == PrinterType.usb ? 'usb' : 'bluetooth');
      await prefs.setString(_prefsKeyPrinterName, printer.name);
    } catch (e) {
      debugPrint('Error saving printer: $e');
    }
  }

  /// Clear saved printer
  Future<void> _clearSavedPrinter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKeySelectedPrinter);
      await prefs.remove(_prefsKeyPrinterType);
      await prefs.remove(_prefsKeyPrinterName);
    } catch (e) {
      debugPrint('Error clearing saved printer: $e');
    }
  }

  /// Scan for USB printers
  Future<List<PrinterDevice>> scanUSBPrinters() async {
    _isScanning = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final devices = await UsbSerial.listDevices();
      final printers = <PrinterDevice>[];

      for (final device in devices) {
        // Filter for common thermal printer vendor IDs
        // VSC printers and other ESC/POS printers
        if (_isLikelyPrinter(device)) {
          printers.add(PrinterDevice(
            id: device.deviceId.toString(),
            name: device.productName ?? 'USB Printer',
            type: PrinterType.usb,
            device: device,
          ));
        }
      }

      _isScanning = false;
      notifyListeners();
      return printers;
    } catch (e) {
      _isScanning = false;
      _errorMessage = 'Gagal memindai printer USB: $e';
      notifyListeners();
      return [];
    }
  }

  /// Check if USB device is likely a printer
  bool _isLikelyPrinter(UsbDevice device) {
    // Common thermal printer vendor IDs (add more as needed)
    // This is a heuristic - actual detection may vary
    return true; // For now, accept all USB serial devices
  }

  /// Scan for Bluetooth printers
  /// [showAllDevices] if true, shows all Bluetooth devices, not just those matching printer patterns
  Future<List<PrinterDevice>> scanBluetoothPrinters({bool showAllDevices = false}) async {
    _isScanning = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check Bluetooth permission
      final permissionStatus = await Permission.bluetoothScan.request();
      if (!permissionStatus.isGranted) {
        throw Exception('Izin Bluetooth tidak diberikan');
      }

      // Check if Bluetooth is available
      if (await FlutterBluePlus.isSupported == false) {
        throw Exception('Bluetooth tidak didukung pada perangkat ini');
      }

      final printers = <PrinterDevice>[];
      final seenDevices = <String>{};

      // First, get already bonded/paired devices (these might not be advertising)
      try {
        final bondedDevices = await FlutterBluePlus.bondedDevices;
        for (final device in bondedDevices) {
          final name = device.platformName.isNotEmpty 
              ? device.platformName 
              : device.remoteId.toString();

          // Include bonded devices (filter only if showAllDevices is false)
          if ((showAllDevices || _isLikelyBluetoothPrinter(name)) && !seenDevices.contains(device.remoteId.toString())) {
            seenDevices.add(device.remoteId.toString());
            printers.add(PrinterDevice(
              id: device.remoteId.toString(),
              name: name,
              type: PrinterType.bluetooth,
              device: device,
            ));
          }
        }
      } catch (e) {
        debugPrint('Error getting bonded devices: $e');
        // Continue with scan even if bonded devices fail
      }

      // Then, start scan for advertising devices
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
      
      // Listen for scan results
      _bluetoothSubscription?.cancel();
      _bluetoothSubscription = FlutterBluePlus.scanResults.listen((results) {
        bool foundNew = false;
        for (final result in results) {
          final device = result.device;
          final name = device.platformName.isNotEmpty 
              ? device.platformName 
              : device.remoteId.toString();

          // Filter for likely printers (check name patterns) or show all if enabled
          if ((showAllDevices || _isLikelyBluetoothPrinter(name)) && !seenDevices.contains(device.remoteId.toString())) {
            seenDevices.add(device.remoteId.toString());
            printers.add(PrinterDevice(
              id: device.remoteId.toString(),
              name: name,
              type: PrinterType.bluetooth,
              device: device,
            ));
            foundNew = true;
          }
        }
        // Notify listeners when new devices are found during scan
        if (foundNew) {
          notifyListeners();
        }
      });

      // Wait for scan to complete
      await Future.delayed(const Duration(seconds: 10));
      await FlutterBluePlus.stopScan();
      _bluetoothSubscription?.cancel();
      _bluetoothSubscription = null;

      _isScanning = false;
      notifyListeners();
      return printers;
    } catch (e) {
      _isScanning = false;
      await FlutterBluePlus.stopScan();
      _bluetoothSubscription?.cancel();
      _bluetoothSubscription = null;
      _errorMessage = 'Gagal memindai printer Bluetooth: $e';
      notifyListeners();
      return [];
    }
  }

  /// Check if Bluetooth device name suggests it's a printer
  bool _isLikelyBluetoothPrinter(String name) {
    final lowerName = name.toLowerCase();
    return lowerName.contains('printer') ||
        lowerName.contains('print') ||
        lowerName.contains('pos') ||
        lowerName.contains('thermal') ||
        lowerName.contains('vsc') ||
        lowerName.contains('tm-') ||
        lowerName.contains('58') ||
        lowerName.contains('rpp') || // RPP printer series (e.g., rpp02N)
        lowerName.startsWith('rpp'); // RPP printers often start with "rpp"
  }

  /// Connect to USB printer
  Future<void> connectToUSBPrinter(PrinterDevice printer) async {
    if (printer.type != PrinterType.usb) {
      throw Exception('Printer bukan tipe USB');
    }

    _isConnecting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final usbDevice = printer.device as UsbDevice;
      
      // Open port (permission is requested automatically)
      final port = await usbDevice.create();
      if (port == null) {
        throw Exception('Gagal membuka port USB. Pastikan izin USB diberikan.');
      }

      // Configure port (9600 baud, 8N1 is default for most thermal printers)
      port.setDTR(true);
      port.setRTS(true);

      _usbPort = port;
      _connectedPrinter = printer;
      await _savePrinter(printer);

      _isConnecting = false;
      notifyListeners();
    } catch (e) {
      _isConnecting = false;
      _errorMessage = 'Gagal terhubung ke printer USB: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Connect to Bluetooth printer
  Future<void> connectToBluetoothPrinter(PrinterDevice printer) async {
    if (printer.type != PrinterType.bluetooth) {
      throw Exception('Printer bukan tipe Bluetooth');
    }

    _isConnecting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final bluetoothDevice = printer.device as BluetoothDevice;

      // Check if already connected
      if (bluetoothDevice.isConnected) {
        _connectedPrinter = printer;
        await _savePrinter(printer);
        _isConnecting = false;
        notifyListeners();
        return;
      }

      // Connect to device
      await bluetoothDevice.connect(timeout: const Duration(seconds: 15));

      // Discover services
      final services = await bluetoothDevice.discoverServices();
      
      // Find serial port service (SPP)
      BluetoothService? serialService;
      for (final service in services) {
        if (service.uuid.toString().toUpperCase().contains('00001101') || // SPP UUID
            service.characteristics.isNotEmpty) {
          serialService = service;
          break;
        }
      }

      if (serialService == null) {
        await bluetoothDevice.disconnect();
        throw Exception('Layanan serial tidak ditemukan pada printer');
      }

      _connectedPrinter = printer;
      await _savePrinter(printer);

      _isConnecting = false;
      notifyListeners();
    } catch (e) {
      _isConnecting = false;
      _errorMessage = 'Gagal terhubung ke printer Bluetooth: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Connect to printer (auto-detect type)
  Future<void> connectToPrinter(PrinterDevice printer) async {
    if (printer.type == PrinterType.usb) {
      await connectToUSBPrinter(printer);
    } else {
      await connectToBluetoothPrinter(printer);
    }
  }

  /// Disconnect from printer
  Future<void> disconnect() async {
    try {
      if (_connectedPrinter == null) return;

      if (_connectedPrinter!.type == PrinterType.usb) {
        await _usbPort?.close();
        _usbPort = null;
      } else {
        final bluetoothDevice = _connectedPrinter!.device as BluetoothDevice;
        if (bluetoothDevice.isConnected) {
          await bluetoothDevice.disconnect();
        }
      }

      _connectedPrinter = null;
      await _clearSavedPrinter();
      notifyListeners();
    } catch (e) {
      debugPrint('Error disconnecting printer: $e');
      _connectedPrinter = null;
      await _clearSavedPrinter();
      notifyListeners();
    }
  }

  /// Send data to USB printer
  Future<void> _sendUSBData(Uint8List data) async {
    if (_usbPort == null || _connectedPrinter == null) {
      throw Exception('Printer tidak terhubung');
    }

    try {
      // Write data directly to USB port
      await _usbPort!.write(data);
    } catch (e) {
      throw Exception('Gagal mengirim data ke printer: $e');
    }
  }

  /// Send data to Bluetooth printer
  Future<void> _sendBluetoothData(Uint8List data) async {
    if (_connectedPrinter == null || _connectedPrinter!.type != PrinterType.bluetooth) {
      throw Exception('Printer Bluetooth tidak terhubung');
    }

    try {
      final bluetoothDevice = _connectedPrinter!.device as BluetoothDevice;
      
      if (!bluetoothDevice.isConnected) {
        throw Exception('Printer Bluetooth terputus');
      }

      final services = await bluetoothDevice.discoverServices();
      BluetoothCharacteristic? writeCharacteristic;

      // Find write characteristic
      for (final service in services) {
        for (final characteristic in service.characteristics) {
          if (characteristic.properties.write || characteristic.properties.writeWithoutResponse) {
            writeCharacteristic = characteristic;
            break;
          }
        }
        if (writeCharacteristic != null) break;
      }

      if (writeCharacteristic == null) {
        throw Exception('Karakteristik tulis tidak ditemukan');
      }

      // Write data in chunks (BLE has MTU limits)
      const chunkSize = 20; // BLE typical MTU
      for (int i = 0; i < data.length; i += chunkSize) {
        final end = (i + chunkSize < data.length) ? i + chunkSize : data.length;
        final chunk = data.sublist(i, end);
        await writeCharacteristic.write(chunk, withoutResponse: true);
        await Future.delayed(const Duration(milliseconds: 10)); // Small delay between chunks
      }
    } catch (e) {
      throw Exception('Gagal mengirim data ke printer Bluetooth: $e');
    }
  }

  /// Print receipt bytes
  Future<void> printBytes(List<int> bytes) async {
    if (_connectedPrinter == null) {
      throw Exception('Printer tidak terhubung. Silakan pilih printer terlebih dahulu.');
    }

    try {
      final data = Uint8List.fromList(bytes);

      if (_connectedPrinter!.type == PrinterType.usb) {
        await _sendUSBData(data);
      } else {
        await _sendBluetoothData(data);
      }
    } catch (e) {
      _errorMessage = 'Gagal mencetak: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Print test receipt
  Future<void> printTestReceipt() async {
    if (_connectedPrinter == null) {
      throw Exception('Printer tidak terhubung');
    }

    try {
      final builder = ReceiptBuilder();

      // Header
      builder.addHeader(
        storeName: 'TEST PRINT',
        address: 'VSC TM 58V Thermal Printer',
        phone: 'ESC/POS Compatible',
      );

      // Test sections
      builder.addSection([
        ...PrinterCommands.align(TextAlign.center),
        ...PrinterCommands.textSize(width: 2, height: 2),
        ...PrinterCommands.bold(true),
        ...PrinterCommands.textLine('TEST PRINT'),
        ...PrinterCommands.bold(false),
        ...PrinterCommands.textSize(width: 1, height: 1),
        ...PrinterCommands.emptyLines(2),
      ]);

      // Date/time - use simple manual format to avoid locale initialization issues
      final now = DateTime.now();
      final day = now.day.toString().padLeft(2, '0');
      final month = now.month.toString().padLeft(2, '0');
      final year = now.year.toString();
      final hour = now.hour.toString().padLeft(2, '0');
      final minute = now.minute.toString().padLeft(2, '0');
      final second = now.second.toString().padLeft(2, '0');
      final dateString = '$day/$month/$year $hour:$minute:$second';
      builder.addSection([
        ...PrinterCommands.align(TextAlign.center),
        ...PrinterCommands.textLine('Tanggal: $dateString'),
        ...PrinterCommands.emptyLines(1),
      ]);

      // Alignment tests
      builder.addSection([
        ...PrinterCommands.divider(),
        ...PrinterCommands.emptyLines(1),
        ...PrinterCommands.align(TextAlign.left),
        ...PrinterCommands.textLine('Kiri (Left)'),
        ...PrinterCommands.align(TextAlign.center),
        ...PrinterCommands.textLine('Tengah (Center)'),
        ...PrinterCommands.align(TextAlign.right),
        ...PrinterCommands.textLine('Kanan (Right)'),
        ...PrinterCommands.emptyLines(1),
        ...PrinterCommands.divider(),
        ...PrinterCommands.emptyLines(1),
      ]);

      // Bold/large text test
      builder.addSection([
        ...PrinterCommands.align(TextAlign.center),
        ...PrinterCommands.textSize(width: 1, height: 1),
        ...PrinterCommands.textLine('Normal Text'),
        ...PrinterCommands.bold(true),
        ...PrinterCommands.textLine('Bold Text'),
        ...PrinterCommands.bold(false),
        ...PrinterCommands.textSize(width: 2, height: 2),
        ...PrinterCommands.textLine('Large Text'),
        ...PrinterCommands.textSize(width: 1, height: 1),
        ...PrinterCommands.emptyLines(1),
        ...PrinterCommands.divider(),
        ...PrinterCommands.emptyLines(1),
      ]);

      // QR test
      builder.addQRCode('TEST123456', label: 'QR Code Test');

      // Footer
      builder.addFooter(thankYouMessage: 'Test Selesai');

      // Print
      final receiptBytes = builder.build();
      await printBytes(receiptBytes);
    } catch (e) {
      _errorMessage = 'Gagal mencetak test: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Manually disconnect printer and dispose service (for app shutdown)
  /// Normally you should just use disconnect() which keeps the service alive
  Future<void> disconnectAndDispose() async {
    await disconnect();
    _cleanupResources();
    _isDisposed = true;
    _instance = null; // Clear singleton instance
    super.dispose();
  }

  /// Clean up resources without disconnecting printer
  void _cleanupResources() {
    _bluetoothSubscription?.cancel();
    _bluetoothSubscription = null;
    // Don't close USB port here - let disconnect() handle it if needed
  }

  @override
  void dispose() {
    // For singleton pattern, dispose() should NOT disconnect the printer
    // Widgets should remove listeners but NOT call dispose() on the service
    // Only disconnectAndDispose() should clean up everything and disconnect
    if (_isDisposed) {
      _cleanupResources();
      super.dispose();
    }
    // Otherwise, do nothing - keep the service and printer connection alive
  }
}

