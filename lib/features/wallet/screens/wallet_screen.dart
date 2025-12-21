import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:ryde/payment_module/presentation/payment_screen.dart';
import 'package:ryde/features/wallet/controllers/wallet_controller.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final WalletController controller = Get.put(WalletController());
    final FirebaseAuth auth = FirebaseAuth.instance;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('My Wallet'),
        elevation: 0,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () => controller.loadWalletData(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                _buildWalletBalanceCard(controller),
                const SizedBox(height: 16),
                _buildActionButtons(context, controller, auth),
                const SizedBox(height: 24),
                _buildTransactionHistory(controller),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildWalletBalanceCard(WalletController controller) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: Colors.grey[400],
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Wallet Balance',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(
            () => Text(
              '₹${controller.walletBalance.value.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Available for withdrawal',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    WalletController controller,
    FirebaseAuth auth,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _addMoney(context, controller, auth),
              icon: const Icon(Icons.add),
              label: const Text('Add Money'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _withdrawMoney(context, controller, auth),
              icon: const Icon(Icons.arrow_upward),
              label: const Text('Withdraw'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[800],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addMoney(
    BuildContext context,
    WalletController controller,
    FirebaseAuth auth,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          userId: auth.currentUser?.uid ?? '',
          title: 'Add Money to Wallet',
          initialAmount: null,
          primaryColor: Colors.black,
          onPaymentSuccess: (amount, paymentId) {
            controller.handleAddMoneySuccess(amount, paymentId);
          },
          onPaymentFailed: () {
            Get.snackbar(
              'Error',
              'Failed to add money. Please try again.',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.grey[800],
              colorText: Colors.white,
            );
          },
        ),
      ),
    );
    if (result == true) {
      controller.loadWalletData();
    }
  }

  Future<void> _withdrawMoney(
    BuildContext context,
    WalletController controller,
    FirebaseAuth auth,
  ) async {
    if (controller.walletBalance.value <= 0) {
      Get.snackbar(
        'Error',
        'Insufficient balance to withdraw',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.grey[800],
        colorText: Colors.white,
      );
      return;
    }
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          userId: auth.currentUser?.uid ?? '',
          title: 'Withdraw Money',
          initialAmount: null,
          primaryColor: Colors.grey[800],
          onPaymentSuccess: (amount, paymentId) {
            controller.handleWithdrawSuccess(amount, paymentId);
          },
          onPaymentFailed: () {
            Get.snackbar(
              'Error',
              'Failed to withdraw money. Please try again.',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.grey[800],
              colorText: Colors.white,
            );
          },
        ),
      ),
    );
    if (result == true) {
      controller.loadWalletData();
    }
  }

  Widget _buildTransactionHistory(WalletController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Recent Transactions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Obx(() {
          if (controller.transactions.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No transactions yet',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.transactions.length,
            itemBuilder: (context, index) {
              final transaction = controller.transactions[index];
              return _buildTransactionItem(transaction);
            },
          );
        }),
      ],
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final type = transaction['type'] ?? 'unknown';
    final amount = (transaction['amount'] ?? 0.0).toDouble();
    final timestamp = transaction['timestamp'] as Timestamp?;
    final description = transaction['description'] ?? 'Transaction';
    final status = transaction['status'] ?? 'completed';
    final isCredit = type == 'credit' || type == 'add';
    final DateTime? dateTime = timestamp?.toDate();
    final amountColor = isCredit ? Colors.green[700] : Colors.red[700];
    final iconColor = isCredit ? Colors.green[600] : Colors.red[600];
    final iconBgColor = isCredit ? Colors.green[50] : Colors.red[50];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          description,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${isCredit ? '+' : '-'}₹${amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: amountColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dateTime != null
                            ? DateFormat(
                                'MMM dd, yyyy • hh:mm a',
                              ).format(dateTime)
                            : 'Date unavailable',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                  if (status != 'completed') ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[800],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
