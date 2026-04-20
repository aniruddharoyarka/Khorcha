import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { income, expense, transfer } // <-- Added transfer

class TransactionModel {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String category;
  final TransactionType type;
  final String wallet;
  final String? toWallet; // <-- NEW: Destination for transfers
  final String? note;
  final double guiltValue;

  //Subscription
  final bool isSubscription;
  final int? billingCycle; //monthwise
  final DateTime? nextPaymentDate;

  TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    required this.type,
    this.wallet = 'Cash',
    this.toWallet, // <-- NEW
    required this.guiltValue,
    this.note,
    this.isSubscription = false,
    this.billingCycle,
    this.nextPaymentDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'date': date,
      'category': category,
      'type': type.name,
      'wallet': wallet,
      'toWallet': toWallet, // <-- NEW
      'note': note,
      'guiltValue': guiltValue,
      'isSubscription': isSubscription,
      'billingCycle': billingCycle,
      'nextPaymentDate': nextPaymentDate,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return TransactionModel(
      id: doc.id,
      title: data['title'] ?? '',
      amount: (data['amount'] as num).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      category: data['category'] ?? '',
      type: TransactionType.values.firstWhere(
            (e) => e.name == data['type'],
        orElse: () => TransactionType.expense, // Fallback safely
      ),
      wallet: data['wallet'] ?? 'Cash',
      toWallet: data['toWallet'], // <-- NEW
      guiltValue: (data['guiltValue'] as num?)?.toDouble() ?? 0.0,
      note: data['note'],
      isSubscription: data['isSubscription'] ?? false,
      billingCycle: data['billingCycle'],
      nextPaymentDate: data['nextPaymentDate'] != null
          ? (data['nextPaymentDate'] as Timestamp).toDate()
          : null,
    );
  }
}