import 'package:flutter/material.dart';
import '../../controllers/customer_controller.dart';

class CustomerSearchFilterSection extends StatelessWidget {
  final CustomerController controller;

  const CustomerSearchFilterSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Cari & Filter Pelanggan",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: controller.setSearchQuery,
            decoration: InputDecoration(
              hintText: 'Cari nama, nomor telepon, email, atau alamat...',
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6366F1)),
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
          const SizedBox(height: 16),
          // Filter chips
          Wrap(
            spacing: 8,
            children: controller.filterOptions.map((filter) {
              final isSelected = controller.selectedFilter == filter;
              return FilterChip(
                label: Text(filter),
                selected: isSelected,
                onSelected: (_) => controller.setSelectedFilter(filter),
                selectedColor: const Color(0xFF6366F1).withOpacity(0.2),
                checkmarkColor: const Color(0xFF6366F1),
                labelStyle: TextStyle(
                  color: isSelected ? const Color(0xFF6366F1) : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}


