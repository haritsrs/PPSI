import 'package:flutter/material.dart';
import '../services/laporan_controller.dart';
import '../widgets/loading_skeletons.dart';
import '../widgets/responsive_page.dart';
import '../widgets/report_app_bar.dart';
import '../widgets/report_error_state.dart';
import '../widgets/report_content.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: widget.hideAppBar ? null : ReportAppBar(controller: _controller),
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
                      onDateRangePicker: () => _controller.openDateRangePicker(context),
                    ),
        ),
      ),
    );
  }
}
