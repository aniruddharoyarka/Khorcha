import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:khorcha/models/transactions.dart';
import 'package:google_fonts/google_fonts.dart';

class DailyExpenseChart extends StatelessWidget {
  final List<TransactionModel> transactions;
  final DateTime selectedMonth;
  final String selectedChart;
  final Function(String?) onChartChanged;

  const DailyExpenseChart({
    super.key,
    required this.transactions,
    required this.selectedMonth,
    required this.selectedChart,
    required this.onChartChanged,
  });

  @override
  Widget build(BuildContext context) {

    // ONLY EXPENSES
    final expenses = transactions.where((t) =>
    t.type == TransactionType.expense &&
        t.date.month == selectedMonth.month &&
        t.date.year == selectedMonth.year
    ).toList();

    final daysInMonth = DateUtils.getDaysInMonth(
      selectedMonth.year,
      selectedMonth.month,
    );

    // DAILY TOTALS
    Map<int, double> dailyTotals = {};

    for (int i = 1; i <= daysInMonth; i++) {
      dailyTotals[i] = 0;
    }

    for (var tx in expenses) {
      dailyTotals[tx.date.day] =
          (dailyTotals[tx.date.day] ?? 0) + tx.amount;
    }

    // GROUP EVERY 3 DAYS
    const int groupSize = 3;

    List<FlSpot> spots = [];

    int pointIndex = 0;

    for (
    int startDay = 1;
    startDay <= daysInMonth;
    startDay += groupSize
    ) {

      double total = 0;

      for (
      int day = startDay;
      day < startDay + groupSize &&
          day <= daysInMonth;
      day++
      ) {

        total += dailyTotals[day] ?? 0;
      }

      spots.add(
        FlSpot(
          pointIndex.toDouble(),
          total,
        ),
      );

      pointIndex++;
    }

    // MAX Y
    double maxY = 100;

    for (var spot in spots) {
      if (spot.y > maxY) {
        maxY = spot.y;
      }
    }

    maxY += 100;

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
        children: [

          // TITLE
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

          // CHART
          SizedBox(
            height: 240,

            child: LineChart(
              LineChartData(

                minX: 0,
                maxX: (spots.length - 1).toDouble(),

                minY: 0,
                maxY: maxY,

                // GRID
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,

                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.black.withOpacity(0.04),
                      strokeWidth: 1,
                    );
                  },
                ),

                borderData: FlBorderData(
                  show: false,
                ),

                // TITLES
                titlesData: FlTitlesData(

                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),

                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),

                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      interval: maxY / 4,

                      getTitlesWidget: (value, meta) {

                        String text;

                        if (value >= 1000) {
                          text =
                          '৳${(value / 1000).toStringAsFixed(1)}k';
                        } else {
                          text = '৳${value.toInt()}';
                        }

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),

                          child: Text(
                            text,

                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // X AXIS
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,

                      getTitlesWidget: (value, meta) {

                        final index = value.toInt();

                        final startDay =
                            (index * groupSize) + 1;

                        final endDay =
                        ((index + 1) * groupSize)
                            .clamp(1, daysInMonth);

                        return Padding(
                          padding: const EdgeInsets.only(top: 8),

                          child: Text(
                            '$startDay-$endDay',

                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // TOOLTIP
                lineTouchData: LineTouchData(

                  touchTooltipData: LineTouchTooltipData(

                    getTooltipItems: (touchedSpots) {

                      return touchedSpots.map((spot) {

                        final index = spot.x.toInt();

                        final startDay =
                            (index * groupSize) + 1;

                        final endDay =
                        ((index + 1) * groupSize)
                            .clamp(1, daysInMonth);

                        return LineTooltipItem(

                          '$startDay-$endDay\n৳${spot.y.toStringAsFixed(0)}',

                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),

                // LINE
                lineBarsData: [

                  LineChartBarData(

                    spots: spots,

                    isCurved: true,

                    curveSmoothness: 0.35,

                    color: const Color(0xFF03624C),

                    barWidth: 3,

                    isStrokeCapRound: true,

                    dotData: const FlDotData(
                      show: false,
                    ),

                    belowBarData: BarAreaData(
                      show: true,

                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,

                        colors: [

                          const Color(0xFF03624C)
                              .withOpacity(0.22),

                          const Color(0xFF03624C)
                              .withOpacity(0.01),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}