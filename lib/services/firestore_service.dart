import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:khorcha/models/wallet_model.dart';
import '../models/transactions.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  String? get userId => FirebaseAuth.instance.currentUser?.uid;

  static const List<String> defaultWallets = [
    'Cash',
    'bKash',
    'Bank',
    'Metro Card',
  ];

  Future<void> addTransaction(TransactionModel tx) async {
    if (userId == null) return;

    await _db
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .add(tx.toCreateMap());
  }


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


  Future<void> deleteTransaction(String transactionId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .doc(transactionId)
        .delete();
  }


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


  Stream<List<WalletModel>> getWallets() {
    if (userId == null) return const Stream.empty();

    return _db
        .collection('users')
        .doc(userId)
        .collection('wallets')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map((doc) => WalletModel.fromFirestore(doc))
          .toList(),
    );
  }

  Future<void> addWallet(
      String walletName,
      double initialBalance,
      ) async {
    if (userId == null) return;

    await _db
        .collection('users')
        .doc(userId)
        .collection('wallets')
        .add({
      'name': walletName,
      'balance': initialBalance,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  //update wallet
  Future<void> updateWalletBalance(
      String walletName,
      double amount,
      TransactionType type,
      ) async {
    if (userId == null) return;

    final walletSnapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('wallets')
        .where('name', isEqualTo: walletName)
        .get();

    if (walletSnapshot.docs.isEmpty) return;

    final walletDoc = walletSnapshot.docs.first;

    final currentBalance =
    (walletDoc['balance'] as num).toDouble();

    double updatedBalance = currentBalance;

    if (type == TransactionType.income) {
      updatedBalance += amount;
    } else if (type == TransactionType.expense) {
      updatedBalance -= amount;
    }

    await walletDoc.reference.update({
      'balance': updatedBalance,
    });
  }

  Future<void> transferBetweenWallets({
    required String fromWallet,
    required String toWallet,
    required double amount,
  }) async {
    if (userId == null) return;

    final walletCollection = _db
        .collection('users')
        .doc(userId)
        .collection('wallets');

    final fromSnapshot =
    await walletCollection
        .where('name', isEqualTo: fromWallet)
        .get();

    final toSnapshot =
    await walletCollection
        .where('name', isEqualTo: toWallet)
        .get();

    if (fromSnapshot.docs.isEmpty ||
        toSnapshot.docs.isEmpty) {
      return;
    }

    final fromDoc = fromSnapshot.docs.first;
    final toDoc = toSnapshot.docs.first;

    final fromBalance =
    (fromDoc['balance'] as num).toDouble();

    final toBalance =
    (toDoc['balance'] as num).toDouble();

    await fromDoc.reference.update({
      'balance': fromBalance - amount,
    });

    await toDoc.reference.update({
      'balance': toBalance + amount,
    });
  }

  Future<void> reverseWalletBalance(
      TransactionModel transaction,
      ) async {

    if (userId == null) return;

    if (transaction.type == TransactionType.transfer) {

      await transferBetweenWallets(
        fromWallet: transaction.toWallet!,
        toWallet: transaction.wallet,
        amount: transaction.amount,
      );

      return;
    }

    final walletSnapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('wallets')
        .where('name', isEqualTo: transaction.wallet)
        .get();

    if (walletSnapshot.docs.isEmpty) return;

    final walletDoc = walletSnapshot.docs.first;

    final currentBalance =
    (walletDoc['balance'] as num).toDouble();

    double updatedBalance = currentBalance;

    if (transaction.type == TransactionType.expense) {

      updatedBalance += transaction.amount;

    } else if (transaction.type == TransactionType.income) {

      updatedBalance -= transaction.amount;
    }

    await walletDoc.reference.update({
      'balance': updatedBalance,
    });
  }
}