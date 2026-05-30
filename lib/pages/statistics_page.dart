import 'package:flutter/material.dart';
import 'package:khorcha/widgets/daily_expense_chart.dart';
import 'package:khorcha/widgets/expense_pie_chart.dart';
import 'package:khorcha/models/transactions.dart';
import 'package:khorcha/widgets/monthly_summary_card.dart';

class StatisticsPage extends StatefulWidget {
  final List<TransactionModel> transactions;
  const StatisticsPage({super.key, required this.transactions});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

double _calculateGuiltPercentage(List<TransactionModel> transactions) {
  if (transactions.isEmpty) return 0;
  double total = 0;
  for (var t in transactions) {
    total += t.guiltValue;
  }
  return total / transactions.length;
}

String guiltMessage(double value) {
  if (value > 0) {
    return "You were ${value.toStringAsFixed(0)}% happy with your spending last month.";
  } else if (value < 0) {
    return "You were ${value.abs().toStringAsFixed(0)}% sad with your spending last month.";
  }
  return "You felt neutral about your spending last month.";
}

class _StatisticsPageState extends State<StatisticsPage> {
  DateTime currentMonth = DateTime.now();

  void changeMonth(DateTime newMonth) {
    setState(() {
      currentMonth = newMonth;
    });
  }

  List<TransactionModel> get filteredTransactions {
    return widget.transactions.where((t) {
      return t.date.year == currentMonth.year &&
          t.date.month == currentMonth.month;
    }).toList();
  }

  String selectedChart = 'Category Breakdown';

  Map<String, dynamic> _calculateCategoryGuilt(List<TransactionModel> transactions) {
    final expenses = transactions.where((t) => t.type == TransactionType.expense).toList();
    if (expenses.isEmpty) return {'hasData': false};

    Map<String, List<double>> categoryGuilts = {};
    for (var t in expenses) {
      if (!categoryGuilts.containsKey(t.category)) {
        categoryGuilts[t.category] = [];
      }
      categoryGuilts[t.category]!.add(t.guiltValue);
    }

    String happiestCategory = "None";
    double highestAvgGuilt = -101;

    String saddestCategory = "None";
    double lowestAvgGuilt = 101;

    categoryGuilts.forEach((category, guiltList) {
      double avg = guiltList.reduce((a, b) => a + b) / guiltList.length;

      if (avg > highestAvgGuilt) {
        highestAvgGuilt = avg;
        happiestCategory = category;
      }
      if (avg < lowestAvgGuilt) {
        lowestAvgGuilt = avg;
        saddestCategory = category;
      }
    });

    return {
      'happiestCategory': happiestCategory,
      'highestAvgGuilt': highestAvgGuilt,
      'saddestCategory': saddestCategory,
      'lowestAvgGuilt': lowestAvgGuilt,
      'hasData': categoryGuilts.isNotEmpty,
    };
  }

  @override
  Widget build(BuildContext context) {
    String highestExpenseTitle = "No Data";
    double highestExpenseAmount = 0;
    String highestIncomeTitle = "No Data";
    double highestIncomeAmount = 0;

    double guiltPercentage = _calculateGuiltPercentage(filteredTransactions);

    Map<String, dynamic> guiltInsights = _calculateCategoryGuilt(filteredTransactions);

    for (var t in filteredTransactions) {
      if (t.type == TransactionType.expense) {
        if (t.amount > highestExpenseAmount) {
          highestExpenseAmount = t.amount;
          highestExpenseTitle = t.title;
        }
      } else if (t.type == TransactionType.income) {
        if (t.amount > highestIncomeAmount) {
          highestIncomeAmount = t.amount;
          highestIncomeTitle = t.title;
        }
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6), // Match dashboard
      appBar: AppBar(
        title: const Text("Statistics", style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
          children: [
            MonthlySummaryCard(
              transactions: widget.transactions,
              currentMonth: currentMonth,
              onMonthChanged: changeMonth,
            ),
            const SizedBox(height: 20),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),

              child: selectedChart == 'Category Breakdown'

                  ? ExpensePieChart(
                key: const ValueKey('pie'),
                transactions: filteredTransactions,
                selectedMonth: currentMonth,
                selectedChart: selectedChart,
                onChartChanged: (value) {
                  setState(() {
                    selectedChart = value!;
                  });
                },
              )

                  : DailyExpenseChart(
                key: const ValueKey('daily'),
                transactions: filteredTransactions,
                selectedMonth: currentMonth,
                selectedChart: selectedChart,
                onChartChanged: (value) {
                  setState(() {
                    selectedChart = value!;
                  });
                },
              )
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _buildHighlightCard(
                    title: "Highest Expense",
                    itemName: highestExpenseTitle,
                    amount: highestExpenseAmount,
                    isExpense: true,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildHighlightCard(
                    title: "Highest Income",
                    itemName: highestIncomeTitle,
                    amount: highestIncomeAmount,
                    isExpense: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildSentimentCard(guiltPercentage),
            const SizedBox(height: 20),

            _buildGuiltInsightsCard(guiltInsights),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightCard({
    required String title,
    required String itemName,
    required double amount,
    required bool isExpense,
  }) {
    final Color color = isExpense ? Colors.redAccent : const Color(0xFF03624C);
    final IconData iconData = isExpense ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;

    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            itemName,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            "৳${amount.toStringAsFixed(0)}",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildSentimentCard(double guiltPercentage) {
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mood, color: Colors.orange, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Overall Sentiment",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54),
                ),
                const SizedBox(height: 4),
                Text(
                  guiltMessage(guiltPercentage),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuiltInsightsCard(Map<String, dynamic> guiltData) {
    if (guiltData['hasData'] != true) return const SizedBox();

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Spending Psychology",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87),
          ),
          const SizedBox(height: 20),

          _buildInsightRow(
            title: "Most Regretted Category",
            category: guiltData['saddestCategory'],
            guiltValue: guiltData['lowestAvgGuilt'],
            isPositive: false,
          ),
          const Divider(height: 30, thickness: 1, color: Color(0xFFF4F7F6)),
          _buildInsightRow(
            title: "Happiest Category",
            category: guiltData['happiestCategory'],
            guiltValue: guiltData['highestAvgGuilt'],
            isPositive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow({required String title, required String category, required double guiltValue, required bool isPositive}) {
    final Color color = isPositive ? const Color(0xFF03624C) : Colors.redAccent;
    final IconData icon = isPositive ? Icons.sentiment_very_satisfied_rounded : Icons.sentiment_very_dissatisfied_rounded;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54),
              ),
              const SizedBox(height: 4),
              Text(
                category,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            "${guiltValue > 0 ? '+' : ''}${guiltValue.toStringAsFixed(0)}%",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color),
          ),
        ),
      ],
    );
  }
}