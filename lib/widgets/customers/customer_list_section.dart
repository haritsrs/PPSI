import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/customer_controller.dart';
import '../../models/customer_model.dart';
import 'customer_card.dart';

class CustomerListSection extends StatelessWidget {
  final CustomerController controller;
  final VoidCallback onAddCustomer;
  final void Function(Customer) onCustomerTap;
  final void Function(Customer) onEditCustomer;
  final void Function(Customer) onDeleteCustomer;

  const CustomerListSection({
    super.key,
    required this.controller,
    required this.onAddCustomer,
    required this.onCustomerTap,
    required this.onEditCustomer,
    required this.onDeleteCustomer,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Daftar Pelanggan (${controller.filteredCustomers.length})",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onAddCustomer();
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Tambah Pelanggan'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF6366F1),
                  backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          controller.isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              : controller.filteredCustomers.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.people_outline_rounded,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              controller.searchQuery.isNotEmpty || controller.selectedFilter != 'Semua'
                                  ? 'Tidak ada pelanggan yang sesuai'
                                  : 'Belum ada pelanggan',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: controller.filteredCustomers.length,
                      itemBuilder: (context, index) {
                        final customer = controller.filteredCustomers[index];
                        return CustomerCard(
                          customer: customer,
                          onTap: () => onCustomerTap(customer),
                          onEdit: () => onEditCustomer(customer),
                          onDelete: () => onDeleteCustomer(customer),
                        );
                      },
                    ),
        ],
      ),
    );
  }
}

