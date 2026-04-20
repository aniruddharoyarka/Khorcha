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
  // Currently selected filters
  String selectedTypeFilter = 'All';
  String selectedWalletFilter = 'All Wallets';

  final List<String> typeFilters = ['All', 'Income', 'Expense', 'Transfer'];

  @override
  Widget build(BuildContext context) {
    // Dynamically extract unique wallets from the user's transactions
    Set<String> uniqueWallets = {'All Wallets'};
    for (var tx in widget.transactions) {
      if (tx.wallet.isNotEmpty) uniqueWallets.add(tx.wallet);
      if (tx.toWallet != null && tx.toWallet!.isNotEmpty) uniqueWallets.add(tx.toWallet!);
    }
    // Sort wallets alphabetically but keep 'All Wallets' at the front
    List<String> walletFilters = uniqueWallets.toList()..sort();
    walletFilters.remove('All Wallets');
    walletFilters.insert(0, 'All Wallets');

    // Filter the transactions based on both selected type AND wallet
    List<TransactionModel> filteredList = widget.transactions.where((t) {
      // 1. Check Type
      bool matchesType = true;
      if (selectedTypeFilter == 'Income') matchesType = t.type == TransactionType.income;
      if (selectedTypeFilter == 'Expense') matchesType = t.type == TransactionType.expense;
      if (selectedTypeFilter == 'Transfer') matchesType = t.type == TransactionType.transfer;

      // 2. Check Wallet
      bool matchesWallet = true;
      if (selectedWalletFilter != 'All Wallets') {
        // Match if either the source wallet or destination wallet matches
        matchesWallet = (t.wallet == selectedWalletFilter || t.toWallet == selectedWalletFilter);
      }

      return matchesType && matchesWallet;
    }).toList();

    // Sort the filtered list by date (newest first)
    filteredList.sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text("Transaction History", style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black87)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type Filters (Horizontal Scroll)
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: typeFilters.length,
                    itemBuilder: (context, index) {
                      final filter = typeFilters[index];
                      final isSelected = selectedTypeFilter == filter;
                      return GestureDetector(
                        onTap: () => setState(() => selectedTypeFilter = filter),
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF03624C) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF03624C) : Colors.grey.shade300,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            filter,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // Wallet Filters (Horizontal Scroll)
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: walletFilters.length,
                    itemBuilder: (context, index) {
                      final filter = walletFilters[index];
                      final isSelected = selectedWalletFilter == filter;
                      return GestureDetector(
                        onTap: () => setState(() => selectedWalletFilter = filter),
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF03624C).withOpacity(0.1) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF03624C) : Colors.grey.shade300,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            filter,
                            style: TextStyle(
                              color: isSelected ? const Color(0xFF03624C) : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Transaction List
          Expanded(
            child: filteredList.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              physics: const BouncingScrollPhysics(),
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

  Widget _buildEmptyState() {
    return Padding(
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
            selectedTypeFilter == 'All' && selectedWalletFilter == 'All Wallets'
                ? "No Transactions Yet"
                : "No Matches Found",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87),
          ),
          const SizedBox(height: 10),
          Text(
            selectedTypeFilter == 'All' && selectedWalletFilter == 'All Wallets'
                ? "Your history is empty. Start adding some expenses or income to track your money!"
                : "You don't have any transactions matching the selected filters.",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.4),
          ),
        ],
      ),
    );
  }
}