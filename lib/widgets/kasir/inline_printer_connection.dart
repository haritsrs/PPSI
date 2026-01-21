import 'package:flutter/material.dart';
import '../../controllers/printer_controller.dart';

/// Inline printer connection indicator widget
/// Non-blocking UI that shows printer status without opening dialogs
class InlinePrinterConnection extends StatefulWidget {
  final PrinterService printerService;
  final bool showActions;
  final VoidCallback? onConnected;
  final VoidCallback? onDisconnected;

  const InlinePrinterConnection({
    super.key,
    required this.printerService,
    this.showActions = false,
    this.onConnected,
    this.onDisconnected,
  });

  @override
  State<InlinePrinterConnection> createState() => _InlinePrinterConnectionState();
}

class _InlinePrinterConnectionState extends State<InlinePrinterConnection> {
  @override
  void initState() {
    super.initState();
    widget.printerService.addListener(_onPrinterStatusChanged);
  }

  @override
  void dispose() {
    widget.printerService.removeListener(_onPrinterStatusChanged);
    super.dispose();
  }

  void _onPrinterStatusChanged() {
    if (mounted) {
      setState(() {});
      if (widget.printerService.isConnected) {
        widget.onConnected?.call();
      } else {
        widget.onDisconnected?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = widget.printerService.isConnected;
    final isConnecting = widget.printerService.isConnecting;
    final printer = widget.printerService.connectedPrinter;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isConnected
            ? Colors.green.withOpacity(0.1)
            : Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isConnected
              ? Colors.green.withOpacity(0.3)
              : Colors.amber.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isConnected ? Icons.print_rounded : Icons.print_disabled_rounded,
            size: 18,
            color: isConnected ? Colors.green[700] : Colors.amber[700],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isConnecting
                      ? 'Menghubungkan...'
                      : isConnected
                          ? 'Printer Terhubung'
                          : 'Printer Tidak Terhubung',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isConnected ? Colors.green[700] : Colors.amber[700],
                  ),
                ),
                if (isConnected && printer != null)
                  Text(
                    printer.name,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (widget.showActions && !isConnecting) ...[
            const SizedBox(width: 8),
            if (isConnected)
              TextButton.icon(
                onPressed: () async {
                  await widget.printerService.disconnect();
                },
                icon: const Icon(Icons.link_off, size: 14),
                label: const Text('Putus', style: TextStyle(fontSize: 11)),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

