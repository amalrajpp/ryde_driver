import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ryde/features/wallet/controllers/wallet_service.dart';

class WalletController extends GetxController {
  final WalletService _walletService = WalletService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Observable variables
  var walletBalance = 0.0.obs;
  var transactions = <Map<String, dynamic>>[].obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadWalletData();
  }

  Future<void> loadWalletData() async {
    try {
      isLoading.value = true;

      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        isLoading.value = false;
        return;
      }

      // Fetch balance
      final balance = await _walletService.getWalletBalance(userId);

      // Fetch transaction history
      final txnHistory = await _walletService.getTransactionHistory(userId);

      walletBalance.value = balance;
      transactions.value = txnHistory;
      isLoading.value = false;
    } catch (e) {
      print('Error loading wallet data: $e');
      isLoading.value = false;
      Get.snackbar(
        'Error',
        'Failed to load wallet data',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> handleAddMoneySuccess(double amount, String paymentId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final success = await _walletService.addMoneyToWallet(
        userId: userId,
        amount: amount,
        paymentId: paymentId,
      );

      if (success) {
        Get.snackbar(
          'Success',
          'Money added successfully!',
          snackPosition: SnackPosition.BOTTOM,
        );
        await loadWalletData();
      }
    } catch (e) {
      print('Error in handleAddMoneySuccess: $e');
      Get.snackbar(
        'Error',
        'Failed to add money: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> handleWithdrawSuccess(double amount, String paymentId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Validate amount against balance
      if (amount > walletBalance.value) {
        Get.snackbar(
          'Error',
          'Amount exceeds available balance',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final success = await _walletService.withdrawMoneyFromWallet(
        userId: userId,
        amount: amount,
        paymentId: paymentId,
      );

      if (success) {
        Get.snackbar(
          'Success',
          'Withdrawal request submitted successfully!',
          snackPosition: SnackPosition.BOTTOM,
        );
        await loadWalletData();
      }
    } catch (e) {
      print('Error in handleWithdrawSuccess: $e');
      Get.snackbar(
        'Error',
        'Failed to withdraw: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
