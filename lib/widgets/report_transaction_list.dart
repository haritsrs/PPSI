import 'package:flutter/material.dart';
import '../controllers/laporan_controller.dart';
import '../models/transaction_model.dart';
import 'transaction_card.dart';

class ReportTransactionList extends StatelessWidget {
  final LaporanController controller;
  final Function(Transaction) onShowTransactionDetail;
  final Function(Transaction) onQuickPrint;

  const ReportTransactionList({
    super.key,
    required this.controller,
    required this.onShowTransactionDetail,
    required this.onQuickPrint,
  });

  Widget _buildTransactionDismissBackground({
    required Color color,
    required IconData icon,
    required Alignment alignment,
    required String label,
  }) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredTransactions = controller.filteredTransactions;

    if (filteredTransactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                controller.transactions.isEmpty
                    ? "Belum ada transaksi"
                    : "Tidak ada transaksi yang cocok",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredTransactions.length,
      itemBuilder: (context, index) {
        final transaction = filteredTransactions[index];
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 220 + (index * 12)),
          curve: Curves.easeOutCubic,
          tween: Tween<double>(begin: 0, end: 1),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, (1 - value) * 16),
                child: child,
              ),
            );
          },
          child: Dismissible(
            key: ValueKey('transaction-${transaction.id}'),
            background: _buildTransactionDismissBackground(
              color: Colors.indigo.shade100,
              icon: Icons.visibility_rounded,
              alignment: Alignment.centerLeft,
              label: 'Detail',
            ),
            secondaryBackground: _buildTransactionDismissBackground(
              color: Colors.green.shade100,
              icon: Icons.print_rounded,
              alignment: Alignment.centerRight,
              label: 'Cetak',
            ),
            confirmDismiss: (direction) async {
              if (direction == DismissDirection.startToEnd) {
                onShowTransactionDetail(transaction);
              } else {
                onQuickPrint(transaction);
              }
              return false;
            },
            child: TransactionCard(
              transaction: transaction,
              onTap: () => onShowTransactionDetail(transaction),
            ),
          ),
        );
      },
    );
  }
}

