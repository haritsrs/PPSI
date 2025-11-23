import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/laporan_controller.dart';
import 'export_dialog.dart';

class ReportAppBar extends StatelessWidget implements PreferredSizeWidget {
  final LaporanController controller;
  final VoidCallback? onExportPDF;
  final VoidCallback? onExportExcel;

  const ReportAppBar({
    super.key,
    required this.controller,
    this.onExportPDF,
    this.onExportExcel,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.analytics_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            "Laporan",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              ExportDialog.show(
                context,
                onExportPDF: onExportPDF ?? () {},
                onExportExcel: onExportExcel ?? () {},
              );
            },
            icon: const Icon(Icons.download_rounded, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

