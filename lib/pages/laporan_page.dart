import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../controllers/laporan_controller.dart';
import '../models/transaction_model.dart';
import '../services/report_export_service.dart';
import '../utils/error_helper.dart';
import '../utils/snackbar_helper.dart';
import '../widgets/loading_skeletons.dart';
import '../widgets/responsive_page.dart';
import '../widgets/report_app_bar.dart';
import '../widgets/report_error_state.dart';
import '../widgets/report_content.dart';
import '../widgets/download_success_dialog.dart';
import '../widgets/transaction_detail_modal.dart';
import '../widgets/print_receipt_dialog.dart';

class LaporanPage extends StatefulWidget {
  final bool hideAppBar;
  
  const LaporanPage({super.key, this.hideAppBar = false});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  late final LaporanController _controller;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = LaporanController();
    _controller.addListener(_onControllerChanged);
    _controller.initialize();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleExportPDF() async {
    try {
      await initializeDateFormatting('id_ID', null);
      final file = await _controller.exportToPDF();

      if (!mounted) return;

      if (file == null) {
        SnackbarHelper.showError(context, 'Gagal membuat file PDF.');
        return;
      }

      DownloadSuccessDialog.show(
        context: context,
        filePath: file.path,
        fileName: file.path.split(Platform.pathSeparator).last,
        fileType: 'PDF',
        onShare: () async {
          try {
            await ReportExportService.shareFile(file, _controller.getPeriodText());
          } catch (e) {
            if (mounted) {
              SnackbarHelper.showError(context, 'Error sharing: $e');
            }
          }
        },
      );
    } catch (error) {
      if (!mounted) return;
      final message = getFriendlyErrorMessage(
        error,
        fallbackMessage: 'Gagal membuat laporan PDF.',
      );
      SnackbarHelper.showError(context, message);
    }
  }

  Future<void> _handleExportExcel() async {
    try {
      await initializeDateFormatting('id_ID', null);
      final file = await _controller.exportToExcel();

      if (!mounted) return;

      if (file == null) {
        SnackbarHelper.showError(context, 'Gagal membuat file Excel.');
        return;
      }

      DownloadSuccessDialog.show(
        context: context,
        filePath: file.path,
        fileName: file.path.split(Platform.pathSeparator).last,
        fileType: 'Excel',
        onShare: () async {
          try {
            await ReportExportService.shareFile(file, _controller.getPeriodText());
          } catch (e) {
            if (mounted) {
              SnackbarHelper.showError(context, 'Error sharing: $e');
            }
          }
        },
      );
    } catch (error) {
      if (!mounted) return;
      final message = getFriendlyErrorMessage(
        error,
        fallbackMessage: 'Gagal membuat laporan Excel.',
      );
      SnackbarHelper.showError(context, message);
    }
  }

  Future<void> _handleShowTransactionDetail(Transaction transaction) async {
    try {
      final fullTransactionData = await _controller.getTransactionDetail(transaction.id);

      if (!mounted) return;

      if (fullTransactionData == null) {
        SnackbarHelper.showError(context, 'Gagal memuat detail transaksi.');
        return;
      }

      TransactionDetailModal.show(
        context,
        transaction: transaction,
        fullTransactionData: fullTransactionData,
        databaseService: _controller.databaseService,
        onPrint: () {
          Navigator.pop(context);
          _handleQuickPrint(transaction);
        },
        onCancelled: () {
          _controller.refreshTransactions();
        },
      );
    } catch (error) {
      if (!mounted) return;
      final message = getFriendlyErrorMessage(
        error,
        fallbackMessage: 'Gagal memuat detail transaksi.',
      );
      SnackbarHelper.showError(context, message);
    }
  }

  Future<void> _handleQuickPrint(Transaction transaction) async {
    try {
      final fullTransactionData = await _controller.getTransactionForPrint(transaction.id);

      if (!mounted) return;

      if (fullTransactionData == null) {
        SnackbarHelper.showError(context, 'Detail transaksi tidak ditemukan.');
        return;
      }

      showDialog(
        context: context,
        builder: (context) => PrintReceiptDialog(
          transactionId: transaction.id,
          transactionData: fullTransactionData,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final message = getFriendlyErrorMessage(
        error,
        fallbackMessage: 'Gagal menyiapkan struk.',
      );
      SnackbarHelper.showError(context, message);
    }
  }

  Future<void> _handleOpenDateRangePicker() async {
    await initializeDateFormatting('id_ID', null);

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _controller.startDate != null && _controller.endDate != null
          ? DateTimeRange(start: _controller.startDate!, end: _controller.endDate!)
          : null,
      locale: const Locale('id', 'ID'),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6366F1),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1F2937),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      _controller.setDateRange(picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: widget.hideAppBar
          ? null
          : ReportAppBar(
              controller: _controller,
              onExportPDF: _handleExportPDF,
              onExportExcel: _handleExportExcel,
            ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: ResponsivePage(
          child: _controller.showInitialLoader
              ? const SingleChildScrollView(
                  key: ValueKey('reports-loader'),
                  physics: AlwaysScrollableScrollPhysics(),
                  child: ReportListSkeleton(),
                )
              : _controller.showFullErrorState
                  ? ReportErrorState(controller: _controller)
                  : ReportContent(
                      controller: _controller,
                      searchController: _searchController,
                      onDateRangePicker: _handleOpenDateRangePicker,
                      onShowTransactionDetail: _handleShowTransactionDetail,
                      onQuickPrint: _handleQuickPrint,
                    ),
        ),
      ),
    );
  }
}
