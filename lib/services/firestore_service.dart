import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transactions.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  String? get userId => FirebaseAuth.instance.currentUser?.uid;

  //add tx
  Future<void> addTransaction(TransactionModel tx) async {
    if (userId == null) return;

    await _db
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .add(tx.toCreateMap());
  }

  //fetch tx
  Stream<List<TransactionModel>> getTransactions() {
    if (userId == null) return const Stream.empty();

    return _db
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TransactionModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Delete a transaction
  Future<void> deleteTransaction(String transactionId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .doc(transactionId)
        .delete();
  }

  //editTransaction
  Future<void> updateTransaction(TransactionModel transaction) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .doc(transaction.id)
          .update(transaction.toMap());
    }
  }
}
