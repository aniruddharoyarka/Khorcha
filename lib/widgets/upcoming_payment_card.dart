import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:khorcha/models/transactions.dart';
import '../pages/transaction_page.dart';
import '../services/firestore_service.dart';

class UpcomingPaymentCard extends StatelessWidget {
  final TransactionModel payment;

  const UpcomingPaymentCard({super.key, required this.payment});

  // =========================
  // MARK AS PAID
  // =========================
  Future<void> _markSubscriptionAsPaid(BuildContext context, TransactionModel parentSub) async {
    final firestoreService = FirestoreService();
    final today = DateTime.now();

    try {
      TransactionModel paymentRecord = TransactionModel(
        id: '',
        title: parentSub.title,
        amount: parentSub.amount,
        date: today,
        category: parentSub.category,
        type: TransactionType.expense,
        wallet: parentSub.wallet,
        guiltValue: parentSub.guiltValue,
        note: 'Subscription logged on ${today.day}/${today.month}/${today.year}',
        isSubscription: false,
      );

      await firestoreService.addTransaction(paymentRecord);

      DateTime baseDate = parentSub.nextPaymentDate ?? today;
      int year = baseDate.year;
      int month = baseDate.month + (parentSub.billingCycle ?? 1);
      int originalDay = parentSub.date.day;

      while (month > 12) {
        month -= 12;
        year += 1;
      }

      int daysInNextMonth = DateUtils.getDaysInMonth(year, month);
      int clampedDay = originalDay > daysInNextMonth ? daysInNextMonth : originalDay;

      DateTime newNextPaymentDate = DateTime(year, month, clampedDay);

      TransactionModel updatedSub = TransactionModel(
        id: parentSub.id,
        title: parentSub.title,
        amount: parentSub.amount,
        date: parentSub.date,
        category: parentSub.category,
        type: parentSub.type,
        wallet: parentSub.wallet,
        toWallet: parentSub.toWallet,
        guiltValue: parentSub.guiltValue,
        note: parentSub.note,
        isSubscription: parentSub.isSubscription,
        billingCycle: parentSub.billingCycle,
        nextPaymentDate: newNextPaymentDate,
      );

      await firestoreService.updateTransaction(updatedSub);

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Payment logged successfully!"),
            backgroundColor: Color(0xFF03624C),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  // =========================
  // ENABLE BUTTON LOGIC
  // =========================
  bool _canMarkAsPaid(DateTime? date) {
    if (date == null) return false;

    final today = DateTime.now();

    final todayOnly = DateTime(today.year, today.month, today.day);
    final paymentDateOnly = DateTime(date.year, date.month, date.day);

    return !todayOnly.isBefore(paymentDateOnly);
  }

  // =========================
  // SMART DATE TEXT
  // =========================
  String _getDueText(DateTime? date) {
    if (date == null) return "No schedule";

    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference == 0) return "Today";
    if (difference == 1) return "Tomorrow";
    if (difference < 0) return "Overdue";
    if (difference <= 7) return "In $difference days";

    return "${date.day} ${_getMonthName(date.month)}";
  }

  String _getMonthName(int month) {
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return months[month - 1];
  }

  Color _getDueColor(DateTime? date) {
    if (date == null) return Colors.grey;

    final diff = date.difference(DateTime.now()).inDays;

    if (diff < 0) return Colors.redAccent;
    if (diff <= 2) return Colors.orange;
    return Colors.green;
  }

  // =========================
  // BOTTOM SHEET
  // =========================
  void _showTransactionDetails(BuildContext context, TransactionModel transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final canMarkPaid = _canMarkAsPaid(transaction.nextPaymentDate);

        return Container(
          padding: const EdgeInsets.all(25),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),

              CircleAvatar(
                radius: 35,
                backgroundColor: const Color(0xFF03624C).withOpacity(0.1),
                child: const Icon(Icons.autorenew,
                    color: Color(0xFF03624C), size: 35),
              ),
              const SizedBox(height: 15),

              Text(transaction.title,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),

              const SizedBox(height: 5),

              Text("৳${transaction.amount.toStringAsFixed(0)}",
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF03624C))),

              const SizedBox(height: 25),

              _buildDetailRow("Category", transaction.category, Icons.category_outlined),
              const SizedBox(height: 15),

              _buildDetailRow("Wallet", transaction.wallet, Icons.account_balance_wallet_outlined),
              const SizedBox(height: 15),

              _buildDetailRow(
                "Next Payment",
                _getDueText(transaction.nextPaymentDate),
                Icons.calendar_month_rounded,
              ),

              const SizedBox(height: 30),

              // MARK AS PAID BUTTON (WITH LOGIC)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: canMarkPaid
                      ? () => _markSubscriptionAsPaid(ctx, transaction)
                      : null,
                  icon: Icon(
                    Icons.check_circle_outline,
                    color: canMarkPaid ? Colors.white : Colors.white70,
                  ),
                  label: Text(
                    canMarkPaid
                        ? "Mark as Paid"
                        : _getDueText(transaction.nextPaymentDate),
                    style: TextStyle(
                      color: canMarkPaid ? Colors.white : Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canMarkPaid
                        ? const Color(0xFF03624C)
                        : Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          ctx,
                          MaterialPageRoute(
                            builder: (context) =>
                                TransactionPage(transactionToEdit: transaction),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit_outlined, color: Colors.black87),
                      label: const Text("Edit",
                          style: TextStyle(color: Colors.black87)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {

                        final user = FirebaseAuth.instance.currentUser;

                        if (user == null) return;

                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .collection('transactions')
                            .doc(transaction.id)
                            .update({
                          'isSubscription': false,
                          'billingCycle': null,
                          'nextPaymentDate': null,
                        });

                        if (ctx.mounted) {
                          Navigator.pop(ctx);

                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text("Subscription cancelled"),
                              backgroundColor: Color(0xFF03624C),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.cancel_outlined,
                          color: Colors.redAccent),
                      label: const Text("Cancel",
                          style: TextStyle(color: Colors.redAccent)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent.withOpacity(0.1),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
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
            Text(label,
                style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500)),
          ],
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.black87),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // =========================
  // CARD UI
  // =========================
  @override
  Widget build(BuildContext context) {
    final dueText = _getDueText(payment.nextPaymentDate);
    final dueColor = _getDueColor(payment.nextPaymentDate);

    return GestureDetector(
      onTap: () => _showTransactionDetails(context, payment),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 15, bottom: 10, top: 5),
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
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF03624C).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.autorenew,
                  color: Color(0xFF03624C), size: 20),
            ),

            const SizedBox(height: 10),

            Text(
              payment.title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 4),

            Row(
              children: [
                Text(
                  "৳${payment.amount.toStringAsFixed(0)}",
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF03624C)),
                ),
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: dueColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    dueText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: dueColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}