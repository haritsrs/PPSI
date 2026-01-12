import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'export_dialog.dart';

class ReportFilters extends StatelessWidget {
  final String selectedFilter;
  final List<String> filters;
  final String searchQuery;
  final String selectedPaymentMethod;
  final List<String> paymentMethods;
  final bool useDateRange;
  final DateTime? startDate;
  final DateTime? endDate;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onPaymentMethodChanged;
  final VoidCallback onDateRangePicker;
  final TextEditingController searchController;
  final VoidCallback? onExportPDF;
  final VoidCallback? onExportExcel;

  const ReportFilters({
    super.key,
    required this.selectedFilter,
    required this.filters,
    required this.searchQuery,
    required this.selectedPaymentMethod,
    required this.paymentMethods,
    required this.useDateRange,
    this.startDate,
    this.endDate,
    required this.onFilterChanged,
    required this.onSearchChanged,
    required this.onPaymentMethodChanged,
    required this.onDateRangePicker,
    required this.searchController,
    this.onExportPDF,
    this.onExportExcel,
  });

  IconData _getFilterIcon(String filter) {
    switch (filter) {
      case 'Semua':
        return Icons.all_inclusive_rounded;
      case 'Hari Ini':
        return Icons.today_rounded;
      case 'Minggu Ini':
        return Icons.view_week_rounded;
      case 'Bulan Ini':
        return Icons.calendar_month_rounded;
      case 'Kuartal Ini':
        return Icons.calendar_view_month_rounded;
      case 'Tahun Ini':
        return Icons.calendar_today_rounded;
      case 'Sepanjang Waktu':
        return Icons.history_rounded;
      case 'Rentang Tanggal':
        return Icons.date_range_rounded;
      default:
        return Icons.filter_list_rounded;
    }
  }

  String _getFilterDescription(String filter) {
    switch (filter) {
      case 'Semua':
        return 'Tampilkan semua transaksi';
      case 'Hari Ini':
        return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(DateTime.now());
      case 'Minggu Ini':
        return '7 hari terakhir';
      case 'Bulan Ini':
        return DateFormat('MMMM yyyy', 'id_ID').format(DateTime.now());
      case 'Kuartal Ini':
        final now = DateTime.now();
        final quarter = ((now.month - 1) ~/ 3) + 1;
        return 'Kuartal $quarter ${now.year}';
      case 'Tahun Ini':
        return '${DateTime.now().year}';
      case 'Sepanjang Waktu':
        return 'Semua periode';
      case 'Rentang Tanggal':
        return 'Pilih rentang tanggal';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Active filter banner
        if (selectedFilter != 'Semua') Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getFilterIcon(selectedFilter),
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedFilter,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getFilterDescription(selectedFilter),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Daftar Transaksi",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: DropdownButton<String>(
                    value: selectedFilter,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        onFilterChanged(newValue);
                      }
                    },
                    underline: Container(),
                    isDense: true,
                    items: filters.map<DropdownMenuItem<String>>((String value) {
                      final isSelected = value == selectedFilter;
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Row(
                          children: [
                            Icon(
                              _getFilterIcon(value),
                              size: 18,
                              color: isSelected ? const Color(0xFF6366F1) : Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              value,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF1F2937),
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF6366F1)),
                  ),
                ),
                if (onExportPDF != null && onExportExcel != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          ExportDialog.show(
                            context,
                            onExportPDF: onExportPDF!,
                            onExportExcel: onExportExcel!,
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.download_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Ekspor',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Search Bar
        TextField(
          controller: searchController,
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Cari transaksi (ID, pelanggan, total, metode pembayaran)...',
            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6366F1)),
            suffixIcon: searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      searchController.clear();
                      onSearchChanged('');
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
          ),
        ),
        const SizedBox(height: 12),
        // Payment Method Filter
        Row(
          children: [
            const Icon(Icons.payment_rounded, size: 20, color: Color(0xFF6366F1)),
            const SizedBox(width: 8),
            Text(
              'Metode Pembayaran:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButton<String>(
                value: selectedPaymentMethod,
                isExpanded: true,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    onPaymentMethodChanged(newValue);
                  }
                },
                underline: Container(),
                items: paymentMethods.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        // Date range display
        if (useDateRange && startDate != null && endDate != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, color: Color(0xFF6366F1), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${DateFormat('dd/MM/yyyy').format(startDate!)} - ${DateFormat('dd/MM/yyyy').format(endDate!)}',
                    style: const TextStyle(
                      color: Color(0xFF6366F1),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onDateRangePicker,
                  child: const Text('Ubah'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

