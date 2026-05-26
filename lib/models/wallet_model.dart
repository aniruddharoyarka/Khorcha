import 'package:cloud_firestore/cloud_firestore.dart';

class WalletModel {
  final String id;
  final String name;
  final double balance;
  final DateTime createdAt;

  WalletModel({
    required this.id,
    required this.name,
    required this.balance,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'balance': balance,
      'createdAt': createdAt,
    };
  }

  factory WalletModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return WalletModel(
      id: doc.id,
      name: data['name'],
      balance: (data['balance'] as num).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}