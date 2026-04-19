import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:khorcha/widgets/guilt_meter.dart';

import '../models/transactions.dart';
import '../services/firestore_service.dart';

class TransactionPage extends StatefulWidget {
  final TransactionModel? transactionToEdit;

  const TransactionPage({super.key, this.transactionToEdit});

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _newCategoryController = TextEditingController();

  final FocusNode _amountFocusNode = FocusNode();

  String _selectedType = 'Expense';
  String? _selectedCategory;
  DateTime? _selectedDate = DateTime.now();

  String _selectedWallet = 'Cash';
  String _toWallet = 'Metro Card'; // <-- NEW: For transfers

  final List<String> _wallets = [
    'Cash', 'bKash', 'Nagad', 'Rocket', 'Upay', 'Bank', 'Metro Card', 'Rapid Pass'
  ];

  bool _isSubscription = false;
  int _billingCycle = 1;

  bool _isAddingCategory = false;
  double guiltValue = 0.0;
  DateTime? nextPaymentDate;

  final List<String> _incomeCategories = [
    'Salary', 'Business', 'Investments', 'Gifts', 'Rental', 'Other',
  ];
  final List<String> _expenseCategories = [
    'Food', 'Housing', 'Transport', 'Health', 'Travel', 'Shopping',
    'Entertainment', 'Education', 'Finance', 'Miscellaneous',
  ];

  @override
  void initState() {
    super.initState();
    _loadCustomCategories();

    if (widget.transactionToEdit != null) {
      final tx = widget.transactionToEdit!;
      _titleController.text = tx.title;
      _amountController.text = tx.amount.toString();
      _noteController.text = tx.note ?? '';

      // Load the correct type
      if (tx.type == TransactionType.income) _selectedType = 'Income';
      else if (tx.type == TransactionType.transfer) _selectedType = 'Transfer';
      else _selectedType = 'Expense';

      if (tx.type == TransactionType.income && !_incomeCategories.contains(tx.category)) {
        _incomeCategories.add(tx.category);
      } else if (tx.type == TransactionType.expense && !_expenseCategories.contains(tx.category)) {
        _expenseCategories.add(tx.category);
      }

      _selectedCategory = tx.category;
      _selectedDate = tx.date;
      _selectedWallet = tx.wallet.isNotEmpty ? tx.wallet : 'Cash';
      _toWallet = tx.toWallet ?? 'Metro Card';
      guiltValue = tx.guiltValue;
      _isSubscription = tx.isSubscription;
      _billingCycle = tx.billingCycle ?? 1;
    }
  }

  Future<void> _loadCustomCategories() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          if (data.containsKey('customIncomeCategories')) {
            List<String> customIncome = List<String>.from(data['customIncomeCategories']);
            setState(() {
              for (var cat in customIncome) if (!_incomeCategories.contains(cat)) _incomeCategories.add(cat);
            });
          }
          if (data.containsKey('customExpenseCategories')) {
            List<String> customExpense = List<String>.from(data['customExpenseCategories']);
            setState(() {
              for (var cat in customExpense) if (!_expenseCategories.contains(cat)) _expenseCategories.add(cat);
            });
          }
        }
      } catch (e) {
        debugPrint("Error loading custom categories: $e");
      }
    }
  }

  IconData _getWalletIcon(String walletName) {
    if (walletName == 'Cash') return Icons.money_rounded;
    if (walletName == 'Bank') return Icons.account_balance_rounded;
    if (walletName.contains('Card') || walletName.contains('Pass')) return Icons.directions_transit_rounded;
    return Icons.phone_android_rounded;
  }

  Widget _buildWalletLogo(String walletName, {double size = 24, Color? iconColor}) {
    //if (walletName == 'bKash') return Image.asset('assets/wallets/bkash.png', width: size, height: size);
    //if (walletName == 'Nagad') return Image.asset('assets/wallets/nagad.png', width: size, height: size);
    return Icon(_getWalletIcon(walletName), color: iconColor, size: size);
  }

  void _showDatePicker() {
    showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF03624C), onPrimary: Colors.white, onSurface: Colors.black87),
          ),
          child: child!,
        );
      },
    ).then((value) {
      if (value != null) setState(() => _selectedDate = value);
    });
  }

  void _saveNewCategory() async {
    String newCategory = _newCategoryController.text.trim();
    if (newCategory.isNotEmpty) {
      bool isIncome = _selectedType == 'Income';

      setState(() {
        if (isIncome) {
          if (!_incomeCategories.contains(newCategory)) _incomeCategories.add(newCategory);
        } else {
          if (!_expenseCategories.contains(newCategory)) _expenseCategories.add(newCategory);
        }
        _selectedCategory = newCategory;
        _isAddingCategory = false;
        _newCategoryController.clear();
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String fieldName = isIncome ? 'customIncomeCategories' : 'customExpenseCategories';
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          fieldName: FieldValue.arrayUnion([newCategory])
        }, SetOptions(merge: true));
      }
    }
  }

  void _computeNextPaymentDate() {
    if (_isSubscription && _selectedDate != null) {
      int year = _selectedDate!.year;
      int month = _selectedDate!.month + _billingCycle;
      int day = _selectedDate!.day;
      while (month > 12) { month -= 12; year += 1; }
      nextPaymentDate = DateTime(year, month, day);
    } else {
      nextPaymentDate = null;
    }
  }

  void _saveTransaction() async {
    bool isTransfer = _selectedType == 'Transfer';

    if (isTransfer) {
      if (_selectedWallet == _toWallet) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cannot transfer to the same wallet"), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
        );
        return;
      }
      _selectedCategory = 'Transfer'; // Bypass validation
    }

    if (_formKey.currentState!.validate() && _selectedDate != null) {
      _computeNextPaymentDate();
      final firestoreService = FirestoreService();

      TransactionType tType = TransactionType.expense;
      if (_selectedType == 'Income') tType = TransactionType.income;
      else if (_selectedType == 'Transfer') tType = TransactionType.transfer;

      TransactionModel transaction = TransactionModel(
        id: widget.transactionToEdit?.id ?? '',
        title: _titleController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
        date: _selectedDate!,
        category: _selectedCategory!,
        type: tType,
        wallet: _selectedWallet,
        toWallet: isTransfer ? _toWallet : null,
        guiltValue: isTransfer ? 0.0 : guiltValue,
        note: _noteController.text.trim(),
        isSubscription: _isSubscription,
        billingCycle: _billingCycle,
        nextPaymentDate: nextPaymentDate,
      );

      if (widget.transactionToEdit != null) {
        await firestoreService.updateTransaction(transaction);
      } else {
        await firestoreService.addTransaction(transaction);
      }

      if (mounted) Navigator.pop(context);
    } else if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a date"), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _newCategoryController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  // Helper widget to build the horizontal scrollable wallet chips
  Widget _buildWalletSelector(String title, String currentValue, ValueChanged<String> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 30, bottom: 10),
          child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54)),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Row(
            children: _wallets.map((wallet) {
              bool isSelected = currentValue == wallet;
              return GestureDetector(
                onTap: () => onChanged(wallet),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF03624C) : const Color(0xFFF4F7F6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      _buildWalletLogo(wallet, size: 18, iconColor: isSelected ? Colors.white : Colors.grey[500]),
                      const SizedBox(width: 8),
                      Text(
                        wallet,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[700],
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.transactionToEdit != null;
    bool isTransfer = _selectedType == 'Transfer';

    return Scaffold(
      backgroundColor: const Color(0xFF03624C),
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: Text(isEditing ? 'Edit Transaction' : 'Add Transaction', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Top Amount Section
            GestureDetector(
              onTap: () => _amountFocusNode.requestFocus(),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                child: Column(
                  children: [
                    const Text("How much?", style: TextStyle(color: Colors.white70, fontSize: 16)),
                    const SizedBox(height: 10),
                    IntrinsicWidth(
                      child: TextFormField(
                        focusNode: _amountFocusNode,
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 55, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -2),
                        decoration: const InputDecoration(
                          prefixText: "৳ ",
                          prefixStyle: TextStyle(fontSize: 55, fontWeight: FontWeight.w800, color: Colors.white70),
                          border: InputBorder.none,
                          hintText: "0",
                          hintStyle: TextStyle(color: Colors.white38),
                        ),
                        validator: (v) => v!.isEmpty ? "Enter amount" : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom White Card
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(35), topRight: Radius.circular(35)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- UPDATED: 3-WAY TOGGLE ---
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(color: const Color(0xFFF4F7F6), borderRadius: BorderRadius.circular(20)),
                          child: Row(
                            children: [
                              Expanded(child: _buildTypeToggle('Expense')),
                              Expanded(child: _buildTypeToggle('Transfer')),
                              Expanded(child: _buildTypeToggle('Income')),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // --- DYNAMIC WALLET SELECTORS ---
                      if (isTransfer) ...[
                        _buildWalletSelector("From Wallet", _selectedWallet, (w) => setState(() => _selectedWallet = w)),
                        const SizedBox(height: 15),
                        _buildWalletSelector("To Wallet", _toWallet, (w) => setState(() => _toWallet = w)),
                      ] else ...[
                        _buildWalletSelector("Wallet", _selectedWallet, (w) => setState(() => _selectedWallet = w)),
                      ],

                      const SizedBox(height: 25),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        child: Column(
                          children: [
                            _buildModernInput(
                              icon: Icons.title,
                              hint: isTransfer ? "Title (e.g. Metro Top-up)" : "Title",
                              child: TextFormField(
                                controller: _titleController,
                                decoration: const InputDecoration(border: InputBorder.none, hintText: "Title"),
                                validator: (v) => v!.isEmpty ? "Enter a title" : null,
                              ),
                            ),
                            const SizedBox(height: 15),

                            // ONLY SHOW CATEGORY IF NOT A TRANSFER
                            if (!isTransfer) ...[
                              _buildModernInput(
                                icon: Icons.folder_open,
                                hint: "Category",
                                child: _isAddingCategory
                                    ? Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _newCategoryController,
                                        decoration: const InputDecoration(hintText: "New category", border: InputBorder.none),
                                        onSubmitted: (_) => _saveNewCategory(),
                                      ),
                                    ),
                                    IconButton(icon: const Icon(Icons.check, color: Color(0xFF03624C)), onPressed: _saveNewCategory),
                                    IconButton(icon: const Icon(Icons.close, color: Colors.redAccent), onPressed: () => setState(() {
                                      _isAddingCategory = false;
                                      _newCategoryController.clear();
                                    })),
                                  ],
                                )
                                    : DropdownButtonFormField<String>(
                                  value: _selectedCategory,
                                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                                  items: [
                                    ...(_selectedType == 'Income' ? _incomeCategories : _expenseCategories).map((c) => DropdownMenuItem(value: c, child: Text(c))),
                                    const DropdownMenuItem<String>(value: '_add_', child: Text('+ Add a new category', style: TextStyle(color: Color(0xFF03624C), fontWeight: FontWeight.bold))),
                                  ],
                                  onChanged: (val) {
                                    if (val == '_add_') setState(() => _isAddingCategory = true);
                                    else setState(() => _selectedCategory = val);
                                  },
                                  decoration: const InputDecoration(border: InputBorder.none, hintText: "Select Category"),
                                  validator: (val) => val == null ? "Select a category" : null,
                                ),
                              ),
                              const SizedBox(height: 15),
                            ],

                            _buildModernInput(
                              icon: Icons.calendar_today_outlined,
                              hint: "Date",
                              child: GestureDetector(
                                onTap: _showDatePicker,
                                child: Container(
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  child: Text(
                                    _selectedDate != null ? "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}" : "Select Date",
                                    style: TextStyle(fontSize: 16, color: _selectedDate != null ? Colors.black87 : Colors.grey[600]),
                                  ),
                                ),
                              ),
                            ),

                            // ONLY SHOW SUBSCRIPTION IF EXPENSE
                            if (_selectedType == 'Expense') ...[
                              const SizedBox(height: 15),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                                decoration: BoxDecoration(color: const Color(0xFFF4F7F6), borderRadius: BorderRadius.circular(15)),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                          child: const Icon(Icons.autorenew, color: Colors.orange, size: 20),
                                        ),
                                        const SizedBox(width: 15),
                                        const Text("Mark as Subscription", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                    Switch(
                                      value: _isSubscription,
                                      activeColor: const Color(0xFF03624C),
                                      onChanged: (val) => setState(() => _isSubscription = val),
                                    ),
                                  ],
                                ),
                              ),

                              if (_isSubscription) ...[
                                const SizedBox(height: 15),
                                _buildModernInput(
                                  icon: Icons.repeat,
                                  hint: "Billing Cycle",
                                  child: TextFormField(
                                    initialValue: _billingCycle.toString(),
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(suffixText: "Months", border: InputBorder.none),
                                    onChanged: (val) => _billingCycle = int.tryParse(val) ?? 1,
                                  ),
                                ),
                              ]
                            ],

                            // ONLY SHOW GUILT IF EXPENSE
                            if (_selectedType == 'Expense') ...[
                              const SizedBox(height: 25),
                              GuiltMeter(
                                onValueVisibilityChanged: (value) => setState(() => guiltValue = value),
                              ),
                            ],

                            const SizedBox(height: 40),

                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                onPressed: _saveTransaction,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF03624C),
                                  elevation: 5,
                                  shadowColor: const Color(0xFF03624C).withOpacity(0.4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                ),
                                child: Text(isEditing ? "Update Transaction" : "Save Transaction", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeToggle(String type) {
    bool isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
          _selectedCategory = null;
          if (type == 'Income' || type == 'Transfer') _isSubscription = false;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          // Changed: Selected background is now the app's green
          color: isSelected ? const Color(0xFF03624C) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          boxShadow: isSelected
              ? [BoxShadow(color: const Color(0xFF03624C).withOpacity(0.3), blurRadius: 5, offset: const Offset(0, 2))]
              : [],
        ),
        alignment: Alignment.center,
        child: Text(
          type,
          style: TextStyle(
            // Changed: Selected text is now white
              color: isSelected ? Colors.white : Colors.grey[500],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 13
          ),
        ),
      ),
    );
  }

  Widget _buildModernInput({required IconData icon, required String hint, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 2),
      decoration: BoxDecoration(color: const Color(0xFFF4F7F6), borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[500], size: 22),
          const SizedBox(width: 15),
          Expanded(child: child),
        ],
      ),
    );
  }
}