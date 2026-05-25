import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transactions.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  String? get userId => FirebaseAuth.instance.currentUser?.uid;

  // =========================
  // DEFAULT WALLETS
  // =========================
  static const List<String> defaultWallets = [
    'Cash',
    'bKash',
    'Bank',
    'Metro Card',
  ];

  // =========================
  // ADD TX
  // =========================
  Future<void> addTransaction(TransactionModel tx) async {
    if (userId == null) return;

    await _db
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .add(tx.toCreateMap());
  }

  // =========================
  // FETCH TX
  // =========================
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

  // =========================
  // DELETE TX
  // =========================
  Future<void> deleteTransaction(String transactionId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .doc(transactionId)
        .delete();
  }

  // =========================
  // UPDATE TX
  // =========================
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

  // =========================
  // GET USER WALLETS
  // =========================
  Stream<List<String>> getWallets() {
    if (userId == null) return Stream.value(defaultWallets);

    return _db
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) {
      final data = doc.data();

      if (data == null || data['wallets'] == null) {
        return defaultWallets;
      }

      final List<String> customWallets =
      List<String>.from(data['wallets']);

      // Merge old hardcoded wallets with new wallets
      final mergedWallets = {
        ...defaultWallets,
        ...customWallets,
      }.toList();

      return mergedWallets;
    });
  }

  // =========================
  // ADD NEW WALLET
  // =========================
  Future<void> addWallet(String walletName) async {
    if (userId == null) return;

    final cleaned = walletName.trim();

    if (cleaned.isEmpty) return;

    await _db.collection('users').doc(userId).set({
      'wallets': FieldValue.arrayUnion([cleaned])
    }, SetOptions(merge: true));
  }
}