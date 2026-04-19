import 'package:flutter/material.dart';
import 'package:khorcha/models/transactions.dart';
import 'package:khorcha/widgets/recent_transactions_card.dart';

class AllTransactionsPage extends StatefulWidget {
  final List<TransactionModel> transactions;

  const AllTransactionsPage({super.key, required this.transactions});

  @override
  State<AllTransactionsPage> createState() => _AllTransactionsPageState();
}

class _AllTransactionsPageState extends State<AllTransactionsPage> {
  // Currently selected filter
  String selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    // 1. Filter the transactions based on selected type
    List<TransactionModel> filteredList = widget.transactions.where((t) {
      if (selectedFilter == 'All') return true;
      if (selectedFilter == 'Income') return t.type == TransactionType.income;
      if (selectedFilter == 'Expense') return t.type == TransactionType.expense;
      if (selectedFilter == 'Transfer') return t.type == TransactionType.transfer;
      return true;
    }).toList();

    // 2. Sort the filtered list by date (newest first)
    filteredList.sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text("Transaction History", style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: Column(
        children: [
          // Filter Row at the top
          _buildFilterRow(),

          // Transactions List
          Expanded(
            child: filteredList.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: filteredList.length,
              itemBuilder: (context, index) {
                return RecentTransactionsCard(transaction: filteredList[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  // Modern horizontal filter row
  Widget _buildFilterRow() {
    final filters = ['All', 'Expense', 'Income', 'Transfer'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filters.map((filter) {
          final isSelected = selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedFilter = filter; // Update state when a filter is tapped
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF03624C) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isSelected
                      ? [
                    BoxShadow(
                      color: const Color(0xFF03624C).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                      : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    )
                  ],
                  border: Border.all(
                    color: isSelected ? Colors.transparent : Colors.grey.shade200,
                  ),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black54,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Redesigned empty state to dynamically adapt to the active filter
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
              child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF03624C), size: 45),
            ),
            const SizedBox(height: 25),
            Text(
              selectedFilter == 'All' ? "No Transactions Yet" : "No $selectedFilter",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            Text(
              selectedFilter == 'All'
                  ? "Your history is empty. Start adding some expenses or income to track your money!"
                  : "You don't have any $selectedFilter transactions yet.",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}