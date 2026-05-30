import 'package:flutter/material.dart';
import 'package:khorcha/models/transactions.dart';
import 'package:khorcha/widgets/upcoming_payment_card.dart';

class UpcomingPaymentsPage extends StatelessWidget {
  final List<TransactionModel> payments;

  const UpcomingPaymentsPage({super.key, required this.payments});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text("Upcoming Payments", style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: payments.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        itemCount: payments.length,
        itemBuilder: (context, index) {
          return UpcomingPaymentCard(payment: payments[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: const Icon(Icons.event_available_rounded, color: Color(0xFF03624C), size: 45),
            ),
            const SizedBox(height: 25),
            const Text(
              "No Upcoming Payments",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            const Text(
              "You have no subscriptions or scheduled payments right now.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}