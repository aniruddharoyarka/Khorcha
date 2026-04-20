import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DashboardHeader extends StatefulWidget {
  final String name;
  final VoidCallback onProfilePressed;
  final VoidCallback onStatisticsPressed;
  final VoidCallback onCardsPressed; // <-- NEW CALLBACK

  const DashboardHeader({
    super.key,
    required this.name,
    required this.onProfilePressed,
    required this.onStatisticsPressed,
    required this.onCardsPressed, // <-- NEW
  });

  @override
  State<DashboardHeader> createState() => _DashboardHeaderState();
}

class _DashboardHeaderState extends State<DashboardHeader> {
  final user = FirebaseAuth.instance.currentUser;

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour > 4 && hour < 12) return 'Good Morning';
    if (hour > 12 && hour < 18) return 'Good Afternoon';
    return 'Good Evening';
  }

  IconData _getGreetingIcon() {
    var hour = DateTime.now().hour;
    if (hour < 12) return Icons.wb_sunny_rounded;
    if (hour < 17) return Icons.wb_cloudy_rounded;
    return Icons.nights_stay_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left Side: Greeting & Dynamic Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _getGreeting(),
                      style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 6),
                    Icon(_getGreetingIcon(), size: 16, color: Colors.orangeAccent),
                  ],
                ),
                const SizedBox(height: 4),
                if (user != null)
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Text("Loading...", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black26));
                      }
                      final data = snapshot.data!.data() as Map<String, dynamic>?;
                      final name = data?['name'] ?? widget.name;
                      return Text(
                        name,
                        style: const TextStyle(fontSize: 26, letterSpacing: -0.5, fontWeight: FontWeight.w800, color: Colors.black87),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  )
                else
                  Text(
                    widget.name.isNotEmpty ? widget.name : "User",
                    style: const TextStyle(fontSize: 26, letterSpacing: -0.5, fontWeight: FontWeight.w800, color: Colors.black87),
                  ),
              ],
            ),
          ),

          // Right Side: Action Buttons
          Row(
            children: [
              // 1. NEW Cards/Wallet Button
              GestureDetector(
                onTap: widget.onCardsPressed,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF03624C).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.credit_card_rounded, color: Color(0xFF03624C), size: 22),
                ),
              ),
              const SizedBox(width: 10),

              // 3. Profile Avatar
              GestureDetector(
                onTap: widget.onProfilePressed,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF03624C).withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const CircleAvatar(
                    radius: 22,
                    backgroundColor: Color(0xFF03624C),
                    child: Icon(Icons.person_rounded, color: Colors.white, size: 24),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}