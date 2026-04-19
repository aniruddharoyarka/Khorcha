import 'package:flutter/material.dart';

class GuiltMeter extends StatefulWidget {
  final Function(double) onValueVisibilityChanged;
  const GuiltMeter({super.key, required this.onValueVisibilityChanged});

  @override
  State<GuiltMeter> createState() => _GuiltMeter();
}

class _GuiltMeter extends State<GuiltMeter> {
  double guiltValue = 0;

  Color getColor() {
    if (guiltValue < 0) return Colors.redAccent;
    if (guiltValue == 0) return Colors.grey[400]!;
    return const Color(0xFF03624C);
  }

  String getMessage() {
    if (guiltValue <= -80) return "Total regret!";
    if (guiltValue < -30) return "Ouch, that hurts a bit";
    if (guiltValue < 0) return "Maybe a bit impulsive?";
    if (guiltValue == 0) return "It was necessary";
    if (guiltValue <= 40) return "Money well spent!";
    if (guiltValue < 80) return "You absolutely earned this!";
    return "Pure joy! Best purchase ever! ";
  }

  IconData getIcon() {
    if (guiltValue <= -80) return Icons.mood_bad_rounded; // Deep regret
    if (guiltValue < -30) return Icons.sentiment_very_dissatisfied_rounded;
    if (guiltValue < 0) return Icons.sentiment_dissatisfied_rounded;
    if (guiltValue == 0) return Icons.sentiment_neutral_rounded;
    if (guiltValue <= 40) return Icons.sentiment_satisfied_rounded;
    if (guiltValue < 80) return Icons.sentiment_very_satisfied_rounded;
    return Icons.celebration_rounded; // Pure joy / Match the rocket message!
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Expense Guilt Meter",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 15),

          // Dynamic Feedback Message
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Row(
              key: ValueKey<double>(guiltValue),
              children: [
                Icon(getIcon(), color: getColor(), size: 28),
                const SizedBox(width: 10),
                Text(
                  getMessage(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: getColor(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: getColor().withOpacity(0.5),
              inactiveTrackColor: Colors.grey[200],
              thumbColor: getColor(),
              overlayColor: getColor().withOpacity(0.1),
              trackHeight: 6,
            ),
            child: Slider(
              value: guiltValue,
              min: -100,
              max: 100,
              divisions: 20,
              onChanged: (value) {
                setState(() {
                  guiltValue = value;
                });
                widget.onValueVisibilityChanged(guiltValue);
              },
            ),
          ),

          // Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Regret", style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w500)),
              Text("Neutral", style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w500)),
              Text("Happy", style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}