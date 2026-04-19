import 'package:flutter/material.dart';
import 'package:khorcha/models/transactions.dart';

class MonthlySummaryCard extends StatefulWidget {
  final List<TransactionModel> transactions;
  final DateTime currentMonth;
  final Function(DateTime) onMonthChanged;

  const MonthlySummaryCard({
    super.key,
    required this.transactions,
    required this.currentMonth,
    required this.onMonthChanged,
  });

  @override
  State<MonthlySummaryCard> createState() => _MonthlySummaryCardState();
}

class _MonthlySummaryCardState extends State<MonthlySummaryCard> {
  double income = 0;
  double expense = 0;

  String getMonth(int month) {
    const months = [
      "", "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ];
    return months[month];
  }

  void _calculateMonthData() {
    double newIncome = 0;
    double newExpense = 0;

    for (var t in widget.transactions) {
      if (t.date.year == widget.currentMonth.year &&
          t.date.month == widget.currentMonth.month) {

        // FIX: Explicitly check the type to avoid transfers being counted as expenses
        if (t.type == TransactionType.income) {
          newIncome += t.amount;
        } else if (t.type == TransactionType.expense) {
          newExpense += t.amount;
        }
      }
    }

    setState(() {
      income = newIncome;
      expense = newExpense;
    });
  }

  void _previousMonth() {
    final newMonth = DateTime(widget.currentMonth.year, widget.currentMonth.month - 1);
    widget.onMonthChanged(newMonth);
    _calculateMonthData();
  }

  void _nextMonth() {
    final newMonth = DateTime(widget.currentMonth.year, widget.currentMonth.month + 1);
    widget.onMonthChanged(newMonth);
    _calculateMonthData();
  }

  @override
  void initState() {
    super.initState();
    _calculateMonthData();
  }

  @override
  void didUpdateWidget(covariant MonthlySummaryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentMonth != widget.currentMonth || oldWidget.transactions != widget.transactions) {
      _calculateMonthData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Month nav
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _previousMonth,
                icon: const Icon(Icons.arrow_back_ios_rounded, size: 18, color: Colors.black54),
              ),
              Text(
                "${getMonth(widget.currentMonth.month)} ${widget.currentMonth.year}",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              IconButton(
                onPressed: _nextMonth,
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.black54),
              )
            ],
          ),
          const SizedBox(height: 15),
          // Calculated Income-Expense
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Income Block
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF03624C).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_downward_rounded, color: Color(0xFF03624C), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Income", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black54)),
                      Text(
                        "৳${income.toStringAsFixed(0)}",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87),
                      ),
                    ],
                  )
                ],
              ),

              Container(height: 40, width: 1, color: Colors.grey.withOpacity(0.2)),

              // Expense Block
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_upward_rounded, color: Colors.redAccent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Expense", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black54)),
                      Text(
                        "৳${expense.toStringAsFixed(0)}",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87),
                      ),
                    ],
                  )
                ],
              ),
            ],
          )
        ],
      ),
    );
  }
}