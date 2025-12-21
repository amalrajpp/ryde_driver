import 'package:cloud_firestore/cloud_firestore.dart';

class WalletService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Add money to wallet and create transaction record
  Future<bool> addMoneyToWallet({
    required String userId,
    required double amount,
    required String paymentId,
  }) async {
    try {
      final driverRef = _firestore.collection('drivers').doc(userId);

      // Run in a transaction to ensure data consistency
      await _firestore.runTransaction((transaction) async {
        final driverDoc = await transaction.get(driverRef);

        if (!driverDoc.exists) {
          throw Exception('Driver not found');
        }

        final currentBalance = (driverDoc.data()?['walletBalance'] ?? 0.0)
            .toDouble();
        final newBalance = currentBalance + amount;

        // Update wallet balance
        transaction.update(driverRef, {
          'walletBalance': newBalance,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        // Add transaction record
        final transactionRef = driverRef.collection('transactions').doc();
        transaction.set(transactionRef, {
          'type': 'credit',
          'amount': amount,
          'description': 'Money added to wallet',
          'paymentId': paymentId,
          'status': 'completed',
          'timestamp': FieldValue.serverTimestamp(),
          'balanceAfter': newBalance,
        });
      });

      return true;
    } catch (e) {
      print('Error adding money to wallet: $e');
      return false;
    }
  }

  /// Withdraw money from wallet and create transaction record
  Future<bool> withdrawMoneyFromWallet({
    required String userId,
    required double amount,
    required String paymentId,
  }) async {
    try {
      final driverRef = _firestore.collection('drivers').doc(userId);

      // Run in a transaction to ensure data consistency
      await _firestore.runTransaction((transaction) async {
        final driverDoc = await transaction.get(driverRef);

        if (!driverDoc.exists) {
          throw Exception('Driver not found');
        }

        final currentBalance = (driverDoc.data()?['walletBalance'] ?? 0.0)
            .toDouble();

        if (currentBalance < amount) {
          throw Exception('Insufficient balance');
        }

        final newBalance = currentBalance - amount;

        // Update wallet balance
        transaction.update(driverRef, {
          'walletBalance': newBalance,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        // Add transaction record
        final transactionRef = driverRef.collection('transactions').doc();
        transaction.set(transactionRef, {
          'type': 'debit',
          'amount': amount,
          'description': 'Money withdrawn from wallet',
          'paymentId': paymentId,
          'status': 'completed',
          'timestamp': FieldValue.serverTimestamp(),
          'balanceAfter': newBalance,
        });
      });

      return true;
    } catch (e) {
      print('Error withdrawing money from wallet: $e');
      return false;
    }
  }

  /// Get current wallet balance
  Future<double> getWalletBalance(String userId) async {
    try {
      final driverDoc = await _firestore
          .collection('drivers')
          .doc(userId)
          .get();

      if (driverDoc.exists) {
        return (driverDoc.data()?['walletBalance'] ?? 0.0).toDouble();
      }
      return 0.0;
    } catch (e) {
      print('Error getting wallet balance: $e');
      return 0.0;
    }
  }

  /// Get transaction history
  Future<List<Map<String, dynamic>>> getTransactionHistory(
    String userId, {
    int limit = 50,
  }) async {
    try {
      final transactionsSnapshot = await _firestore
          .collection('drivers')
          .doc(userId)
          .collection('transactions')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return transactionsSnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      print('Error getting transaction history: $e');
      return [];
    }
  }
}
