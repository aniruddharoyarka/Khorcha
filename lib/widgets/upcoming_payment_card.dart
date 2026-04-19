import 'package:flutter/material.dart';
import 'package:khorcha/models/transactions.dart';
import '../pages/transaction_page.dart';
import '../services/firestore_service.dart';

class UpcomingPaymentCard extends StatelessWidget {
  final TransactionModel payment;

  const UpcomingPaymentCard({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showTransactionDetails(context, payment),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 15, bottom: 10, top: 5), // Margin for shadow
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF03624C).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.autorenew_rounded, color: Color(0xFF03624C), size: 20),
                ),
                if (payment.nextPaymentDate != null)
                  Text(
                    "${payment.nextPaymentDate!.day}/${payment.nextPaymentDate!.month}",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 13),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              payment.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 5),
            Text(
              "৳${payment.amount.toStringAsFixed(0)}",
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: Color(0xFF03624C)),
            ),
          ],
        ),
      ),
    );
  }

  void _showTransactionDetails(BuildContext context, TransactionModel tx) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 20,
            top: 15,
            left: 25,
            right: 25,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
              ),
              const SizedBox(height: 25),

              // Header
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: const Color(0xFF03624C).withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.autorenew_rounded, color: Color(0xFF03624C), size: 35),
              ),
              const SizedBox(height: 15),
              Text(
                "৳${tx.amount.toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Color(0xFF03624C), letterSpacing: -1),
              ),
              const SizedBox(height: 5),
              Text(
                tx.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 30),

              // Details Group
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F7F6),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Column(
                  children: [
                    _buildDetailRow("Category", tx.category, Icons.category_outlined),
                    const Divider(height: 25, thickness: 1, color: Colors.black12),

                    // Added "Last Paid" row using the base transaction date
                    _buildDetailRow("Last Paid", "${tx.date.day}/${tx.date.month}/${tx.date.year}", Icons.history_rounded),
                    const Divider(height: 25, thickness: 1, color: Colors.black12),

                    if (tx.nextPaymentDate != null) ...[
                      _buildDetailRow("Next Payment", "${tx.nextPaymentDate!.day}/${tx.nextPaymentDate!.month}/${tx.nextPaymentDate!.year}", Icons.event_rounded),
                      const Divider(height: 25, thickness: 1, color: Colors.black12),
                    ],

                    _buildDetailRow("Billing Cycle", tx.billingCycle == 1 ? "Monthly" : "Every ${tx.billingCycle} Months", Icons.update_rounded),

                    if (tx.note != null && tx.note!.isNotEmpty) ...[
                      const Divider(height: 25, thickness: 1, color: Colors.black12),
                      _buildDetailRow("Note", tx.note!, Icons.notes_outlined),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Action Buttons (Edit & Delete)
              Row(
                children: [
                  // Edit Button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context); // Close the modal
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TransactionPage(transactionToEdit: tx),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                      label: const Text("Edit", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF03624C),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),

                  // Delete Button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await FirestoreService().deleteTransaction(tx.id);
                        if (context.mounted) Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Transaction deleted"), backgroundColor: Colors.redAccent),
                        );
                      },
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                      label: const Text("Delete", style: TextStyle(color: Colors.redAccent, fontSize: 15, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent.withOpacity(0.1),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.black54),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w500)),
          ],
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}