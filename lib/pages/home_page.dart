import 'package:flutter/material.dart';
import 'package:khorcha/pages/dashboard_page.dart';
import 'package:khorcha/pages/statistics_page.dart';
import 'package:khorcha/pages/transaction_page.dart';
import 'package:khorcha/models/transactions.dart';

import '../services/firestore_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final FirestoreService _firestoreService = FirestoreService();

  void _navigateToTransactionPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF9FFFC),
      body: StreamBuilder<List<TransactionModel>>(
        stream: _firestoreService.getTransactions(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final transactions = snapshot.data!;

          return IndexedStack(
            index: _currentIndex,
            children: [
              DashboardPage(
                onAddPressed: _navigateToTransactionPage,
                allTransactions: transactions,
              ),
              StatisticsPage(transactions: transactions),
            ],
          );
        },
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xFF03624C),
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            label: "Statistics",
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToTransactionPage,
        backgroundColor:  Color(0xFF03624C),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.add, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
