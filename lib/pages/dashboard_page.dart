import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:khorcha/pages/profile_page.dart';
import 'package:khorcha/pages/upcoming_payments_page.dart';
import 'package:khorcha/services/firestore_service.dart';
import 'package:khorcha/widgets/balance_card.dart';
import 'package:khorcha/widgets/budget_card.dart';
import 'package:khorcha/widgets/dashboard_header.dart';
import 'package:khorcha/widgets/recent_transactions_card.dart';
import 'package:khorcha/widgets/section_title.dart';
import 'package:khorcha/widgets/upcoming_payment_card.dart';
import 'package:khorcha/models/transactions.dart';

import 'all_transactions_page.dart';

class DashboardPage extends StatefulWidget {
  final VoidCallback onAddPressed;
  final List<TransactionModel> allTransactions;

  const DashboardPage({super.key, required this.onAddPressed, required this.allTransactions});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  double? userBudget;
  bool isLoadingBudget = true;
  bool _hasAlerted = false;

  String? walletNameError;
  String? balanceError;

  void _showAddWalletDialog() {
    final controller = TextEditingController();
    final balanceController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {

        String? walletNameError;
        String? balanceError;

        return StatefulBuilder(
          builder: (context, setDialogState) {

            Widget buildInputField({
              required TextEditingController controller,
              required IconData icon,
              required String hint,
              required String? error,
              TextInputType? keyboardType,
              String? prefix,
            }) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: error != null
                            ? Colors.red.shade400
                            : const Color(0xFFE7ECEA),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: controller,
                      keyboardType: keyboardType,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        icon: Icon(
                          icon,
                          color: const Color(0xFF03624C),
                        ),
                        prefixText: prefix,
                        hintText: hint,
                        hintStyle: TextStyle(
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: error != null
                        ? Padding(
                      padding: const EdgeInsets.only(
                        left: 12,
                        top: 8,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 15,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            error,
                            key: ValueKey(error),
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                        : const SizedBox.shrink(),
                  ),
                ],
              );
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),
              child: Container(
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAF9),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    // TOP ICON
                    Container(
                      height: 78,
                      width: 78,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF03624C),
                            const Color(0xFF048B6A),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF03624C)
                                .withOpacity(0.25),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // TITLE
                    const Text(
                      "Create Wallet",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1B1D1C),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      "Add a wallet and track your money beautifully.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.5,
                        height: 1.4,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // WALLET FIELD
                    buildInputField(
                      controller: controller,
                      icon: Icons.wallet_rounded,
                      hint: "Wallet name",
                      error: walletNameError,
                    ),

                    const SizedBox(height: 18),

                    // BALANCE FIELD
                    buildInputField(
                      controller: balanceController,
                      icon: Icons.currency_exchange_rounded,
                      hint: "Initial balance",
                      error: balanceError,
                      keyboardType: TextInputType.number,
                      prefix: "৳ ",
                    ),

                    const SizedBox(height: 34),

                    // BUTTONS
                    Row(
                      children: [

                        // CANCEL
                        Expanded(
                          child: SizedBox(
                            height: 58,
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(18),
                                ),
                              ),
                              child: const Text(
                                "Cancel",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 14),

                        // CREATE
                        Expanded(
                          child: SizedBox(
                            height: 58,
                            child: ElevatedButton(
                              onPressed: () async {

                                final walletName =
                                controller.text.trim();

                                final initialBalance =
                                double.tryParse(
                                  balanceController.text,
                                );

                                setDialogState(() {

                                  walletNameError = null;
                                  balanceError = null;

                                  if (walletName.isEmpty) {
                                    walletNameError =
                                    'Wallet name is required';
                                  }

                                  if (initialBalance == null) {
                                    balanceError =
                                    'Enter a valid amount';
                                  }
                                  else if (initialBalance < 0) {
                                    balanceError =
                                    'Balance cannot be negative';
                                  }
                                });

                                if (walletNameError != null ||
                                    balanceError != null) {
                                  return;
                                }

                                await FirestoreService()
                                    .addWallet(
                                  walletName,
                                  initialBalance!,
                                );

                                if (!mounted) return;

                                Navigator.pop(context);
                                Navigator.pop(context);

                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '$walletName added successfully',
                                    ),
                                    backgroundColor:
                                    const Color(0xFF03624C),
                                    behavior:
                                    SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(14),
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor:
                                const Color(0xFF03624C),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(18),
                                ),
                              ),
                              child: const Text(
                                "Create",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    fetchBudget();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDuePayments();
    });
  }

  @override
  void didUpdateWidget(covariant DashboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_hasAlerted && widget.allTransactions != oldWidget.allTransactions) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkDuePayments();
      });
    }
  }

  Future<void> fetchBudget() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (doc.exists && doc.data() != null && doc.data()!.containsKey('budget')) {
        setState(() {
          userBudget = (doc['budget'] as num).toDouble();
          isLoadingBudget = false;
        });
      } else {
        setState(() {
          userBudget = null;
          isLoadingBudget = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching budget: $e");
      setState(() => isLoadingBudget = false);
    }
  }

  void _checkDuePayments() {
    if (_hasAlerted) return;

    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    final duePayments = widget.allTransactions.where((t) {
      if (!t.isSubscription || t.nextPaymentDate == null) return false;
      final paymentDate = DateTime(t.nextPaymentDate!.year, t.nextPaymentDate!.month, t.nextPaymentDate!.day);
      return paymentDate.isBefore(today) || paymentDate.isAtSameMomentAs(today);
    }).toList();

    if (duePayments.isNotEmpty) {
      _hasAlerted = true;
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 10),
              Text("Payments Due!", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            "You have ${duePayments.length} subscription(s) due for payment. Please check your Upcoming Payments.",
            style: const TextStyle(fontSize: 15, color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Got it", style: TextStyle(color: Color(0xFF03624C), fontWeight: FontWeight.bold)),
            )
          ],
        ),
      );
    }
  }

  // Helper to assign icons to BD wallets
  IconData _getWalletIcon(String walletName) {
    if (walletName == 'Cash') return Icons.money_rounded;
    if (walletName == 'Bank') return Icons.account_balance_rounded;
    if (walletName.contains('Card') || walletName.contains('Pass')) return Icons.directions_transit_rounded;
    return Icons.phone_android_rounded;
  }

  // --- NEW WALLETS BOTTOM SHEET ---
  void _showWalletsBottomSheet(Map<String, double> wallets, double totalBalance) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 20,
            top: 15,
            left: 25,
            right: 25,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
              ),
              const SizedBox(height: 25),

              // Title & Total Balance
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "My Wallets",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  GestureDetector(
                    onTap: _showAddWalletDialog,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF03624C).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Color(0xFF03624C),
                      ),
                    ),
                  ),
                ],
              ),
              //const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    "Total Wealth: ৳${totalBalance.toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF03624C)),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // Vertical List of Wallets
              if (wallets.isEmpty)
                const Text("No active wallets found.", style: TextStyle(color: Colors.black54))
              else
                ...wallets.entries.map((entry) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F7F6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF03624C).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_getWalletIcon(entry.key), color: const Color(0xFF03624C), size: 24),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87),
                          ),
                        ),
                        Text(
                          "৳${entry.value.toStringAsFixed(0)}",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF03624C)),
                        ),
                      ],
                    ),
                  );
                }),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: Colors.grey[200], shape: BoxShape.circle),
            child: Icon(Icons.receipt_long, color: Colors.grey[400], size: 30),
          ),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: Colors.grey[500], fontSize: 15, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final List<TransactionModel> upcomingPayments = widget.allTransactions
        .where((tx) => tx.isSubscription)
        .toList()
      ..sort((a, b) {
        DateTime dateA = a.nextPaymentDate ?? a.date;
        DateTime dateB = b.nextPaymentDate ?? b.date;
        return dateA.compareTo(dateB);
      });
    final List<TransactionModel> limitedUpcomingPayments = upcomingPayments.take(4).toList();

    final List<TransactionModel> sortedTransactions = List.from(widget.allTransactions)
      ..sort((a, b) => b.date.compareTo(a.date));
    final List<TransactionModel> limitedRecentTransactions = sortedTransactions.take(5).toList();

    final DateTime now = DateTime.now();

    double totalExpense = 0.00;
    double totalBalance = 0.0;
    Map<String, double> walletBalances = {};

    return StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('wallets')
            .snapshots(),

        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final walletDocs = snapshot.data!.docs;
          // RESET VALUES EVERY BUILD
          totalBalance = 0;
          walletBalances.clear();
          totalExpense = 0;

// WALLET BALANCES
          for (var doc in walletDocs) {

            final data = doc.data();

            final name = data['name'];

            final balance =
            (data['balance'] as num).toDouble();

            walletBalances[name] = balance;

            totalBalance += balance;
          }

// MONTHLY EXPENSE CALCULATION
          for (var tx in widget.allTransactions) {

            if (tx.type == TransactionType.expense &&
                tx.date.month == now.month &&
                tx.date.year == now.year) {

              totalExpense += tx.amount;
            }
          }

          return Scaffold(
          backgroundColor: const Color(0xFFF4F7F6),
          body: SafeArea(
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 30),
              children: [
                const SizedBox(height: 15),

                DashboardHeader(
                  name: user?.displayName ?? "User",
                  onProfilePressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage()));
                  },
                  onStatisticsPressed: () {},
                  // Connect the new button to our beautiful bottom sheet!
                  onCardsPressed: () => _showWalletsBottomSheet(walletBalances, totalBalance),
                ),

                const SizedBox(height: 15),

                // REVERTED to use Total Expense again!
                BalanceCard(
                  onAddPressed: widget.onAddPressed,
                  totalExpense: totalExpense,
                ),

                const SizedBox(height: 15),

                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();
                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    if (data == null || !data.containsKey('budget')) return const SizedBox();

                    double budget = (data['budget'] as num).toDouble();
                    if (budget <= 0) return const SizedBox();

                    return Column(
                      children: [
                        BudgetCard(spent: totalExpense, total: budget),
                        const SizedBox(height: 15),
                      ],
                    );
                  },
                ),

                SectionTitle(
                  title: "Upcoming Payments",
                  onSeeAll: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => UpcomingPaymentsPage(payments: upcomingPayments)));
                  },
                ),

                const SizedBox(height: 15),

                limitedUpcomingPayments.isEmpty
                    ? _buildEmptyState("No upcoming payments found")
                    : SizedBox(
                  height: 165,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: limitedUpcomingPayments.length,
                    itemBuilder: (context, index) {
                      return UpcomingPaymentCard(payment: limitedUpcomingPayments[index]);
                    },
                  ),
                ),

                const SizedBox(height: 15),

                SectionTitle(
                  title: "Recent Transactions",
                  onSeeAll: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => AllTransactionsPage(transactions: sortedTransactions)));
                  },
                ),

                const SizedBox(height: 15),

                limitedRecentTransactions.isEmpty
                    ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: _buildEmptyState("No transactions found yet"),
                )
                    : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: limitedRecentTransactions.length,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemBuilder: (context, index) {
                    return RecentTransactionsCard(transaction: limitedRecentTransactions[index]);
                  },
                ),
              ],
            ),
          ),
        );
      }
    );
  }
}