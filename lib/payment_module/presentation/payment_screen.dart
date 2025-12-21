import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/payment_gateway_model.dart';
import '../repositories/payment_repository.dart';
import '../services/payment_service.dart';
import '../provider/payment_provider.dart';
import 'widgets/payment_gateway_item_widget.dart';
import 'widgets/payment_success_dialog.dart';
import 'widgets/payment_error_dialog.dart';

/// Main payment screen
class PaymentScreen extends StatefulWidget {
  final String userId;
  final double? initialAmount;
  final String? title;
  final Function(double amount, String paymentId)? onPaymentSuccess;
  final VoidCallback? onPaymentFailed;
  final Color? primaryColor;
  final Color? backgroundColor;

  const PaymentScreen({
    Key? key,
    required this.userId,
    this.initialAmount,
    this.title,
    this.onPaymentSuccess,
    this.onPaymentFailed,
    this.primaryColor,
    this.backgroundColor,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final TextEditingController _amountController = TextEditingController();
  final PaymentService _paymentService = PaymentService();
  double? _selectedAmount;

  @override
  void initState() {
    super.initState();
    if (widget.initialAmount != null) {
      _amountController.text = widget.initialAmount!.toStringAsFixed(2);
      _selectedAmount = widget.initialAmount;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PaymentProvider(
        repository: MockPaymentRepository(),
        paymentService: _paymentService,
      )..initialize(),
      child: Scaffold(
        backgroundColor: widget.backgroundColor ?? Colors.grey[50],
        appBar: AppBar(
          title: Text(
            widget.title ?? 'Payment',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          elevation: 0,
          backgroundColor:
              widget.primaryColor ?? Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
            color: Colors.white,
          ),
        ),
        body: Consumer<PaymentProvider>(
          builder: (context, provider, child) {
            // Handle dialogs
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (provider.showSuccessDialog && mounted) {
                _showSuccessDialog(context, provider);
              } else if (provider.showErrorDialog && mounted) {
                _showErrorDialog(
                  context,
                  provider.errorMessage ?? 'Payment failed',
                );
              }
            });

            if (provider.isLoading) {
              return _buildLoadingState('Loading...');
            } else if (provider.isProcessing) {
              return _buildProcessingState('Processing payment...');
            } else if (provider.errorMessage != null &&
                provider.gateways.isEmpty) {
              return _buildErrorState(context, provider);
            } else if (provider.configuration != null) {
              return _buildPaymentGateways(context, provider);
            }

            return _buildLoadingState('Initializing...');
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState(String? message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProcessingState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please wait...',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, PaymentProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.errorMessage ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                provider.loadGateways();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    widget.primaryColor ?? Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentGateways(BuildContext context, PaymentProvider provider) {
    final size = MediaQuery.of(context).size;

    return SafeArea(
      child: Column(
        children: [
          // Amount selection section
          Container(
            width: size.width,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Amount',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildAmountButton(200)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildAmountButton(400)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildAmountButton(600)),
                  ],
                ),
                if (_selectedAmount != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Selected: ₹${_selectedAmount!.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Payment methods header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                const Text(
                  'Select Payment Method',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (provider.configuration?.enableSaveCard == true)
                  TextButton.icon(
                    onPressed: () {
                      provider.addCard(widget.userId);
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Card'),
                    style: TextButton.styleFrom(
                      foregroundColor:
                          widget.primaryColor ?? Theme.of(context).primaryColor,
                    ),
                  ),
              ],
            ),
          ),

          // Payment gateways list
          Expanded(
            child: provider.gateways.isEmpty
                ? const Center(
                    child: Text(
                      'No payment methods available',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: provider.gateways.length,
                    itemBuilder: (context, index) {
                      final gateway = provider.gateways[index];
                      return PaymentGatewayItemWidget(
                        gateway: gateway,
                        isSelected: provider.selectedIndex == index,
                        onTap: () {
                          provider.selectGateway(index);
                        },
                        onDelete: gateway.isCard
                            ? () => _confirmDeleteCard(
                                context,
                                provider,
                                gateway,
                                index,
                              )
                            : null,
                        primaryColor: widget.primaryColor,
                      );
                    },
                  ),
          ),

          // Continue button
          Container(
            width: size.width,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed:
                  provider.selectedIndex != null && _selectedAmount != null
                  ? () => _processPayment(context, provider)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    widget.primaryColor ?? Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: Colors.grey[300],
              ),
              child: const Text(
                'Continue to Payment',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountButton(double amount) {
    final isSelected = _selectedAmount == amount;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedAmount = amount;
          _amountController.text = amount.toStringAsFixed(2);
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.black : Colors.grey[200],
        foregroundColor: isSelected ? Colors.white : Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? Colors.black : Colors.grey[300]!,
            width: 2,
          ),
        ),
        elevation: isSelected ? 2 : 0,
      ),
      child: Text(
        '₹${amount.toStringAsFixed(0)}',
        style: TextStyle(
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _processPayment(
    BuildContext context,
    PaymentProvider provider,
  ) async {
    final amount = _selectedAmount ?? 0.0;

    // Validate amount
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate amount
    if (!PaymentService.validateAmount(
      amount: amount,
      minimumAmount: provider.configuration?.minimumAmount ?? '0',
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Minimum amount is ${provider.configuration?.currencySymbol ?? '₹'}${provider.configuration?.minimumAmount ?? '0.0'}',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Get selected gateway
    if (provider.selectedIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a payment method'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final gateway = provider.gateways[provider.selectedIndex!];

    // For RazorPay, open the payment UI directly
    if (gateway.type == PaymentGatewayType.razorPay) {
      try {
        debugPrint('💳 Processing RazorPay payment for ₹$amount');

        // Show helpful hint
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '💡 Tip: Use UPI (success@razorpay) or Net Banking for instant test payments!',
            ),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 4),
          ),
        );

        final result = await _paymentService.processRazorPayPayment(
          amount: amount,
          orderId: '', // Empty for test mode
          userName: 'Ryde Driver',
          userEmail: 'driver@ryde.com',
          userPhone: '9999999999',
          onSuccess: (response) {
            if (mounted) {
              debugPrint('✅ Payment Success: ${response.paymentId}');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Payment Successful! ID: ${response.paymentId}',
                  ),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 3),
                ),
              );
              widget.onPaymentSuccess?.call(amount, response.paymentId ?? '');
              Navigator.pop(context, true);
            }
          },
          onFailure: (response) {
            if (mounted) {
              debugPrint(
                '❌ Payment Failed: ${response.code} - ${response.message}',
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Payment Failed: ${response.message ?? 'Unknown error'}',
                  ),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 4),
                ),
              );
              widget.onPaymentFailed?.call();
            }
          },
        );

        if (!result.success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        debugPrint('❌ Payment Exception: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      // For other gateways, use the provider's method
      await provider.processPayment(
        userId: widget.userId,
        amount: amount,
        metadata: {
          'source': 'payment_module',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      // Show success/error dialogs based on result
      if (mounted) {
        if (provider.lastResult != null && provider.lastResult!.success) {
          _showSuccessDialog(context, provider);
        } else if (provider.errorMessage != null) {
          _showErrorDialog(context, provider.errorMessage!);
        }
      }
    }
  }

  void _confirmDeleteCard(
    BuildContext context,
    PaymentProvider provider,
    PaymentGatewayItem gateway,
    int index,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Card'),
        content: Text(
          'Are you sure you want to remove this card ending in ${gateway.lastFourDigits}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await provider.deleteCard(
                userId: widget.userId,
                cardToken: gateway.cardToken!,
                index: index,
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, PaymentProvider provider) {
    final amount = _selectedAmount ?? 0.0;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PaymentSuccessDialog(
        message: 'Payment processed successfully',
        transactionId: provider.lastResult?.transactionId ?? 'N/A',
        onClose: () {
          Navigator.pop(dialogContext);
          widget.onPaymentSuccess?.call(
            amount,
            provider.lastResult?.transactionId ?? '',
          );
          Navigator.pop(context, true);
        },
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (dialogContext) => PaymentErrorDialog(
        message: message,
        onClose: () {
          Navigator.pop(dialogContext);
          widget.onPaymentFailed?.call();
        },
      ),
    );
  }
}
