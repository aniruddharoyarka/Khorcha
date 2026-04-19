import 'package:flutter/material.dart';

class BudgetCard extends StatefulWidget {
  final double spent;
  final double total;

  const BudgetCard({
    super.key,
    required this.spent,
    required this.total,
  });

  @override
  State<BudgetCard> createState() => _BudgetCardState();
}

class _BudgetCardState extends State<BudgetCard> {
  @override
  Widget build(BuildContext context) {
    double progress = widget.total == 0 ? 0 : (widget.spent / widget.total).clamp(0, 1);
    double remaining = widget.total - widget.spent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Title Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF03624C).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.pie_chart_outline, color: Color(0xFF03624C), size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Monthly Budget",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                Text(
                  "৳${widget.spent.toStringAsFixed(0)} / ৳${widget.total.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: const Color(0xFFF0F5F3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress >= 1 ? Colors.redAccent : const Color(0xFF03624C),
                ),
              ),
            ),

            const SizedBox(height: 15),

            /// Bottom Info Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  remaining >= 0
                      ? "Remaining: ৳${remaining.toStringAsFixed(0)}"
                      : "Over budget by ৳${remaining.abs().toStringAsFixed(0)}",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: remaining >= 0 ? const Color(0xFF03624C) : Colors.redAccent,
                  ),
                ),
                Text(
                  "${(progress * 100).toStringAsFixed(0)}%",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: progress >= 1 ? Colors.redAccent : Colors.black87,
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