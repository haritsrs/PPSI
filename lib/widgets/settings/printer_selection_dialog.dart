import 'package:flutter/material.dart';
import '../../services/printer_service.dart';
import '../../utils/snackbar_helper.dart';

class PrinterSelectionDialog extends StatefulWidget {
  final PrinterService printerService;

  const PrinterSelectionDialog({
    super.key,
    required this.printerService,
  });

  @override
  State<PrinterSelectionDialog> createState() => _PrinterSelectionDialogState();
}

class _PrinterSelectionDialogState extends State<PrinterSelectionDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<PrinterDevice> _usbPrinters = [];
  List<PrinterDevice> _bluetoothPrinters = [];
  bool _isScanning = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scanPrinters();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _scanPrinters() async {
    setState(() {
      _isScanning = true;
      _errorMessage = null;
    });

    try {
      // Scan both USB and Bluetooth in parallel
      final results = await Future.wait([
        widget.printerService.scanUSBPrinters(),
        widget.printerService.scanBluetoothPrinters(),
      ]);

      setState(() {
        _usbPrinters = results[0];
        _bluetoothPrinters = results[1];
        _isScanning = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memindai printer: $e';
        _isScanning = false;
      });
    }
  }

  Future<void> _connectToPrinter(PrinterDevice printer) async {
    try {
      await widget.printerService.connectToPrinter(printer);
      if (mounted) {
        Navigator.of(context).pop(printer);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Gagal terhubung: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.print_rounded, color: Color(0xFF6366F1)),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Pilih Printer',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Tabs
            TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF6366F1),
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: 'USB', icon: Icon(Icons.usb_rounded)),
                Tab(text: 'Bluetooth', icon: Icon(Icons.bluetooth_rounded)),
              ],
            ),
            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPrinterList(_usbPrinters, PrinterType.usb),
                  _buildPrinterList(_bluetoothPrinters, PrinterType.bluetooth),
                ],
              ),
            ),
            // Footer
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: _isScanning ? null : _scanPrinters,
                    icon: _isScanning
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded),
                    label: const Text('Refresh'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Batal'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrinterList(List<PrinterDevice> printers, PrinterType type) {
    if (_isScanning) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Memindai printer...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _scanPrinters,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (printers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                type == PrinterType.usb ? Icons.usb_rounded : Icons.bluetooth_rounded,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Tidak ada printer ${type == PrinterType.usb ? 'USB' : 'Bluetooth'} ditemukan',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _scanPrinters,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: printers.length,
      itemBuilder: (context, index) {
        final printer = printers[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: Icon(
              type == PrinterType.usb ? Icons.usb_rounded : Icons.bluetooth_rounded,
              color: const Color(0xFF6366F1),
            ),
            title: Text(
              printer.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              type == PrinterType.usb ? 'USB Printer' : 'Bluetooth Printer',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _connectToPrinter(printer),
          ),
        );
      },
    );
  }
}

