import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            DropdownButton<String>(
              value: selectedFilter,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  onFilterChanged(newValue);
                }
              },
              underline: Container(),
              items: filters.map<DropdownMenuItem<String>>((String value) {
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
              icon: const Icon(Icons.filter_list_rounded, color: Color(0xFF6366F1)),
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

