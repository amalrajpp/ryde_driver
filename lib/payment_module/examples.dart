/// Example: How to integrate the payment module in your app
///
/// This file shows different ways to use the payment module

import 'package:flutter/material.dart';
import 'payment_module.dart';

/// Example 1: Basic Integration
class Example1BasicPayment extends StatelessWidget {
  const Example1BasicPayment({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Example 1: Basic Payment')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentScreen(
                  userId: 'user_123',
                  initialAmount: 50.0,
                  title: 'Add Money to Wallet',
                ),
              ),
            );
          },
          child: const Text('Open Payment Screen'),
        ),
      ),
    );
  }
}

/// Example 2: Payment with Callbacks
class Example2PaymentWithCallbacks extends StatefulWidget {
  const Example2PaymentWithCallbacks({Key? key}) : super(key: key);

  @override
  State<Example2PaymentWithCallbacks> createState() =>
      _Example2PaymentWithCallbacksState();
}

class _Example2PaymentWithCallbacksState
    extends State<Example2PaymentWithCallbacks> {
  String _status = 'No payment made';

  void _openPaymentScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          userId: 'user_123',
          initialAmount: 100.0,
          title: 'Payment',
          onPaymentSuccess: (amount, paymentId) {
            setState(() {
              _status =
                  '✅ Payment successful! Amount: ₹$amount, ID: $paymentId';
            });
          },
          onPaymentFailed: () {
            setState(() {
              _status = '❌ Payment failed!';
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Example 2: With Callbacks')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_status, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _openPaymentScreen,
              child: const Text('Make Payment'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Example 3: Custom Colors
class Example3CustomColors extends StatelessWidget {
  const Example3CustomColors({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Example 3: Custom Colors')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentScreen(
                  userId: 'user_123',
                  initialAmount: 75.0,
                  title: 'Custom Payment',
                  primaryColor: const Color(0xFF6366F1), // Indigo
                  backgroundColor: const Color(0xFFF9FAFB), // Light gray
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
          ),
          child: const Text('Open Custom Payment'),
        ),
      ),
    );
  }
}

/// Example 4: Profile Payment Integration (Like in your requirements)
class Example4ProfilePaymentScreen extends StatelessWidget {
  final String userId;
  final String userName;
  final String? profileImage;
  final double? walletBalance;

  const Example4ProfilePaymentScreen({
    Key? key,
    required this.userId,
    required this.userName,
    this.profileImage,
    this.walletBalance,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment & Wallet'), elevation: 0),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Profile Image
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    backgroundImage: profileImage != null
                        ? NetworkImage(profileImage!)
                        : null,
                    child: profileImage == null
                        ? const Icon(Icons.person, size: 40)
                        : null,
                  ),
                  const SizedBox(height: 12),

                  // User Name
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Wallet Balance
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Wallet: \$${walletBalance?.toStringAsFixed(2) ?? '0.00'}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Quick Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Actions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Add Money Button
                  _buildActionCard(
                    context: context,
                    icon: Icons.add_card,
                    title: 'Add Money',
                    subtitle: 'Top up your wallet',
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentScreen(
                            userId: userId,
                            title: 'Add Money to Wallet',
                            onPaymentSuccess: (amount, paymentId) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Money added successfully! ₹$amount',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Payment Methods Button
                  _buildActionCard(
                    context: context,
                    icon: Icons.payment,
                    title: 'Payment Methods',
                    subtitle: 'Manage your cards',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentScreen(
                            userId: userId,
                            title: 'Payment Methods',
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Transaction History Button
                  _buildActionCard(
                    context: context,
                    icon: Icons.history,
                    title: 'Transaction History',
                    subtitle: 'View all transactions',
                    color: Colors.orange,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Transaction history coming soon!'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

/// Main Demo App
class PaymentModuleDemo extends StatelessWidget {
  const PaymentModuleDemo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Payment Module Demo',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const DemoHomePage(),
    );
  }
}

class DemoHomePage extends StatelessWidget {
  const DemoHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Module Examples')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildExampleCard(
            context: context,
            title: 'Example 1: Basic Payment',
            description: 'Simple payment screen with default settings',
            icon: Icons.payment,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const Example1BasicPayment(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildExampleCard(
            context: context,
            title: 'Example 2: With Callbacks',
            description: 'Handle payment success/failure',
            icon: Icons.check_circle,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const Example2PaymentWithCallbacks(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildExampleCard(
            context: context,
            title: 'Example 3: Custom Colors',
            description: 'Customize the look and feel',
            icon: Icons.palette,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const Example3CustomColors(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildExampleCard(
            context: context,
            title: 'Example 4: Profile Integration',
            description: 'Payment screen in user profile',
            icon: Icons.person,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const Example4ProfilePaymentScreen(
                    userId: 'user_123',
                    userName: 'John Doe',
                    walletBalance: 150.50,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExampleCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Icon(icon, color: Theme.of(context).primaryColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
