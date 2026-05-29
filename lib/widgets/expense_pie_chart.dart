import 'package:flutter/material.dart';
import 'package:khorcha/models/transactions.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

class ExpensePieChart extends StatelessWidget {
  final List<TransactionModel> transactions;
  final DateTime selectedMonth;
  final String selectedChart;
  final Function(String?) onChartChanged;

  const ExpensePieChart({
    super.key,
    required this.transactions,
    required this.selectedMonth,
    required this.selectedChart,
    required this.onChartChanged,
  });

  @override
  Widget build(BuildContext context) {
    final allExpenses = transactions.where((t) =>
    t.type == TransactionType.expense &&
        t.date.month == selectedMonth.month &&
        t.date.year == selectedMonth.year
    ).toList();

    double totalExpense = 0;
    Map<String, double> categoryAmounts = {};

    for (var expense in allExpenses) {
      totalExpense += expense.amount;
      categoryAmounts[expense.category] = (categoryAmounts[expense.category] ?? 0) + expense.amount;
    }

    final List<Color> pieColors = [
      const Color(0xFF64B5F6), const Color(0xFF81C784), const Color(0xFFFFB74D),
      const Color(0xFFE57373), const Color(0xFFBA68C8), const Color(0xFF4FC3F7),
      const Color(0xFFAED581), const Color(0xFFFF8A65),
    ];

    if (allExpenses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5)),
          ],
        ),
        alignment: Alignment.center,
        child: const Text("No expenses to show for this month.", style: TextStyle(color: Colors.black54)),
      );
    }

    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(

                        value: selectedChart,

                        isDense: true,

                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 22,
                          color: Colors.black87,
                        ),

                        borderRadius: BorderRadius.circular(16),

                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),

                        items: [

                          DropdownMenuItem(
                            value: 'Category Breakdown',
                            child: Text(
                              'Expense Breakdown',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          DropdownMenuItem(
                            value: 'Daily Expense Trend',
                            child: Text(
                              'Daily Expense Trend',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],

                        onChanged: onChartChanged,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(

                      selectedChart == 'Category Breakdown'
                          ? 'Category wise spending'
                          : 'Grouped every 3 days',

                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          const SizedBox(height: 35),

          // 1. Bigger Pie Chart
          Center(
            child: SizedBox(
              height: 160, // Increased height for a bigger chart
              child: PieChart(
                PieChartData(
                  sectionsSpace: 3, // Slightly thicker gaps
                  centerSpaceRadius: 50, // Larger empty center space
                  sections: List.generate(categoryAmounts.length, (index) {
                    final category = categoryAmounts.keys.elementAt(index);
                    final amount = categoryAmounts[category]!;
                    return PieChartSectionData(
                      value: amount,
                      color: pieColors[index % pieColors.length],
                      radius: 45, // Thicker colored rings
                      showTitle: false, // Keeps it looking modern and clean
                    );
                  }),
                ),
              ),
            ),
          ),

          const SizedBox(height: 35),

          // 2. Legend & Percentages Below
          Column(
            children: categoryAmounts.entries.map((entry) {
              final index = categoryAmounts.keys.toList().indexOf(entry.key);
              final percentage = (entry.value / totalExpense) * 100;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    // Colored Square Indicator
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: pieColors[index % pieColors.length],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Category Name
                    Expanded(
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                            fontWeight: FontWeight.w600
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Percentage and Actual Amount
                    Text(
                      '৳${entry.value.toStringAsFixed(0)} (${percentage.toStringAsFixed(1)}%)',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.black54
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}