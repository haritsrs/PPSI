import 'package:flutter/material.dart';
import '../../services/settings_controller.dart';
import '../../services/printer_service.dart';
import '../../utils/snackbar_helper.dart';
import 'settings_section.dart';
import 'setting_item.dart';
import 'printer_selection_dialog.dart';

class PrinterSettingsSection extends StatefulWidget {
  final SettingsController controller;

  const PrinterSettingsSection({
    super.key,
    required this.controller,
  });

  @override
  State<PrinterSettingsSection> createState() => _PrinterSettingsSectionState();
}

class _PrinterSettingsSectionState extends State<PrinterSettingsSection> {
  late PrinterService _printerService;

  @override
  void initState() {
    super.initState();
    // Get singleton instance - don't create new one
    _printerService = PrinterService();
    _printerService.addListener(_onPrinterServiceChanged);
  }

  @override
  void dispose() {
    // Only remove listener, don't dispose the service
    // This keeps the printer connected across widget lifecycles
    _printerService.removeListener(_onPrinterServiceChanged);
    super.dispose();
  }

  void _onPrinterServiceChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _handleSelectPrinter() async {
    try {
      final selectedPrinter = await showDialog<PrinterDevice>(
        context: context,
        builder: (context) => PrinterSelectionDialog(printerService: _printerService),
      );

      if (selectedPrinter != null && mounted) {
        await _printerService.connectToPrinter(selectedPrinter);
        await widget.controller.setPrinter(selectedPrinter.toString());
        if (mounted) {
          SnackbarHelper.showSuccess(context, 'Printer berhasil terhubung');
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Gagal memilih printer: $e');
      }
    }
  }

  Future<void> _handleTestPrint() async {
    if (!_printerService.isConnected) {
      SnackbarHelper.showError(context, 'Printer tidak terhubung. Silakan pilih printer terlebih dahulu.');
      return;
    }

    try {
      await _printerService.printTestReceipt();
      if (mounted) {
        SnackbarHelper.showSuccess(context, 'Test print berhasil dikirim ke printer');
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Gagal mencetak test: $e');
      }
    }
  }

  Future<void> _handleDisconnect() async {
    try {
      await _printerService.disconnect();
      await widget.controller.setPrinter('Tidak Ada');
      if (mounted) {
        SnackbarHelper.showSuccess(context, 'Printer berhasil diputus');
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Gagal memutus printer: $e');
      }
    }
  }

  String _getPrinterStatus() {
    if (_printerService.isConnecting) {
      return 'Menghubungkan...';
    }
    if (_printerService.isConnected) {
      return _printerService.connectedPrinter?.toString() ?? 'Terhubung';
    }
    return 'Tidak Terhubung';
  }

  Color _getStatusColor() {
    if (_printerService.isConnecting) {
      return Colors.orange;
    }
    if (_printerService.isConnected) {
      return Colors.green;
    }
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: "Printer Thermal",
      icon: Icons.print_rounded,
      color: const Color(0xFF10B981),
      children: [
        SettingItem(
          icon: Icons.usb_rounded,
          title: "Pilih Printer",
          subtitle: _getPrinterStatus(),
          trailing: Icon(
            Icons.circle,
            size: 12,
            color: _getStatusColor(),
          ),
          onTap: _handleSelectPrinter,
        ),
        if (_printerService.isConnected) ...[
          SettingItem(
            icon: Icons.print_outlined,
            title: "Test Print",
            subtitle: "Cetak test receipt",
            onTap: _handleTestPrint,
          ),
          SettingItem(
            icon: Icons.link_off_rounded,
            title: "Putus Koneksi",
            subtitle: "Putuskan koneksi printer",
            onTap: _handleDisconnect,
          ),
        ],
        SettingItem(
          icon: Icons.print_rounded,
          title: "Aktifkan Printer",
          subtitle: "Cetak struk otomatis",
          trailing: Switch(
            value: widget.controller.printerEnabled,
            onChanged: (value) async {
              await widget.controller.setPrinterEnabled(value);
            },
            activeColor: const Color(0xFF6366F1),
          ),
        ),
        if (_printerService.errorMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _printerService.errorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

