import 'package:flutter/material.dart';
import '../services/laporan_controller.dart';
import 'status_banner.dart';
import 'summary_card.dart';
import 'period_toggle.dart';
import 'revenue_chart.dart';
import 'report_filters.dart';
import 'report_transaction_list.dart';

class ReportContent extends StatelessWidget {
  final LaporanController controller;
  final TextEditingController searchController;
  final VoidCallback onDateRangePicker;

  const ReportContent({
    super.key,
    required this.controller,
    required this.searchController,
    required this.onDateRangePicker,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: controller.refreshTransactions,
      color: const Color(0xFF6366F1),
      displacement: 48,
      child: SingleChildScrollView(
        key: const ValueKey('reports-content'),
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (controller.isOffline)
              StatusBanner(
                color: Colors.orange,
                icon: Icons.wifi_off_rounded,
                message: 'Anda sedang offline. Data dapat tidak terbaru.',
                trailing: TextButton(
                  onPressed: controller.isRetrying ? null : controller.retryLoadTransactions,
                  child: Text(
                    'Segarkan',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
            if (controller.showInlineErrorBanner)
              StatusBanner(
                color: Colors.red,
                icon: Icons.error_outline_rounded,
                message: controller.errorMessage ?? 'Terjadi kesalahan.',
                trailing: TextButton(
                  onPressed: controller.isRetrying ? null : controller.retryLoadTransactions,
                  child: Text(
                    'Coba Lagi',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.red[600],
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
            if (controller.isRetrying && controller.hasLoadedOnce)
              StatusBanner(
                color: Colors.blue,
                icon: Icons.sync_rounded,
                message: 'Menyegarkan data transaksi...',
                trailing: const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                  ),
                ),
              ),
            if (controller.isRefreshing && !controller.showInitialLoader)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(
                  minHeight: 3,
                  color: Color(0xFF6366F1),
                  backgroundColor: Color(0xFFE2E8F0),
                ),
              ),
            // Period Toggle
            PeriodToggle(
              selectedPeriod: controller.selectedPeriod,
              periods: controller.periods,
              onPeriodChanged: controller.setSelectedPeriod,
            ),
            const SizedBox(height: 24),
            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: SummaryCard(
                    title: "Total Penghasilan",
                    value: controller.totalRevenue,
                    icon: Icons.trending_up_rounded,
                    color: const Color(0xFF10B981),
                    isCurrency: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SummaryCard(
                    title: "Total Transaksi",
                    value: controller.totalTransactions.toDouble(),
                    icon: Icons.receipt_long_rounded,
                    color: const Color(0xFF3B82F6),
                    isCurrency: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Chart Section
            RevenueChart(transactions: controller.filteredTransactions),
            const SizedBox(height: 24),
            // Filter and Transaction List
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ReportFilters(
                selectedFilter: controller.selectedFilter,
                filters: controller.filters,
                searchQuery: controller.searchQuery,
                selectedPaymentMethod: controller.selectedPaymentMethod,
                paymentMethods: controller.paymentMethods,
                useDateRange: controller.useDateRange,
                startDate: controller.startDate,
                endDate: controller.endDate,
                onFilterChanged: (filter) {
                  controller.setSelectedFilter(filter);
                  if (filter == 'Rentang Tanggal') {
                    onDateRangePicker();
                  }
                },
                onSearchChanged: controller.setSearchQuery,
                onPaymentMethodChanged: controller.setSelectedPaymentMethod,
                onDateRangePicker: onDateRangePicker,
                searchController: searchController,
              ),
            ),
            const SizedBox(height: 16),
            ReportTransactionList(controller: controller),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

