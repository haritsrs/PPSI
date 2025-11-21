import 'package:flutter/material.dart';
import '../controllers/laporan_controller.dart';
import '../widgets/loading_skeletons.dart';
import '../widgets/responsive_page.dart';
import '../widgets/report_app_bar.dart';
import '../widgets/report_error_state.dart';
import '../widgets/report_content.dart';

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  late final LaporanController _controller;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _periods = ['Hari', 'Minggu', 'Bulan'];
  final List<String> _filters = ['Semua', 'Hari Ini', 'Minggu Ini', 'Bulan Ini', 'Rentang Tanggal'];
  final List<String> _paymentMethods = ['Semua', 'Cash', 'QRIS', 'VirtualAccount'];
  String _selectedPeriod = 'Hari';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: ReportAppBar(controller: _controller),
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
                      periods: _periods,
                      filters: _filters,
                      paymentMethods: _paymentMethods,
                      selectedPeriod: _selectedPeriod,
                      onPeriodChanged: (period) {
                        setState(() {
                          _selectedPeriod = period;
                        });
                      },
                      searchController: _searchController,
                      onDateRangePicker: () => _controller.openDateRangePicker(context),
                    ),
        ),
      ),
    );
  }
}
