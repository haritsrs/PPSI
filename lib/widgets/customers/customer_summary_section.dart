import 'package:flutter/material.dart';
import '../../controllers/customer_controller.dart';
import '../summary_card.dart';
import '../../utils/home_utils.dart';

class CustomerSummarySection extends StatelessWidget {
  final CustomerController controller;

  const CustomerSummarySection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Summary Cards
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                title: "Total Pelanggan",
                value: controller.totalCustomers.toDouble(),
                icon: Icons.people_rounded,
                color: const Color(0xFF3B82F6),
                isCurrency: false,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SummaryCard(
                title: "Pelanggan VIP",
                value: controller.vipCustomers.toDouble(),
                icon: Icons.star_rounded,
                color: const Color(0xFF8B5CF6),
                isCurrency: false,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Total Revenue Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(
              color: const Color(0xFF10B981).withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.attach_money_rounded,
                  color: Color(0xFF10B981),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Total Revenue",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Rp ${formatCurrency(controller.totalRevenue)}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

