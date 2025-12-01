import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// Define custom colors based on the design
class AppColors {
  static const Color primaryText = Color(0xFF2D3436);
  static const Color secondaryText = Color(0xFFA4AAB3);
  static const Color accentYellow = Color(0xFFFFD700);
  static const Color lightYellowBg = Color(0xFFFFFBE8);
  static const Color positiveGreen = Color(0xFF27AE60);
  static const Color infoBlue = Color(0xFF2F80ED);
  static const Color backgroundGrey = Color(0xFFF8F9FD);
  static const Color cardBorder = Color(0xFFEFEFEF);
}

class EarningScreen extends StatefulWidget {
  const EarningScreen({super.key});

  @override
  State<EarningScreen> createState() => _EarningScreenState();
}

class _EarningScreenState extends State<EarningScreen> {
  // Data Variables
  double _totalEarnings = 0.0;
  double _monthlyEarnings = 0.0;
  double _weeklyEarnings = 0.0;
  double _todayEarnings = 0.0;
  List<DocumentSnapshot> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchEarningsData();
  }

  Future<void> _fetchEarningsData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Fetch all bookings for this driver
      // Note: In a production app with thousands of rides, you would implement pagination
      // or use a separate 'aggregations' collection updated via Cloud Functions.
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('booking')
          .where('driver_id', isEqualTo: user.uid)
          //.where('status', isEqualTo: 'completed') // Uncomment this line if you only want completed rides to count
          .get(); // We get all to sort locally to avoid composite index errors during development

      double total = 0;
      double month = 0;
      double week = 0;
      double today = 0;
      List<DocumentSnapshot> validDocs = [];

      DateTime now = DateTime.now();
      DateTime startOfDay = DateTime(now.year, now.month, now.day);
      DateTime startOfWeek = DateTime(
        now.year,
        now.month,
        now.day - (now.weekday - 1),
      );

      DateTime startOfMonth = DateTime(now.year, now.month, 1);

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Safety check if price or created_at is missing
        if (data['price'] == null || data['created_at'] == null) continue;

        double amount = (data['price'] as num).toDouble();
        Timestamp timestamp = data['created_at'] as Timestamp;
        DateTime date = timestamp.toDate();

        // Add to valid list for transaction history
        validDocs.add(doc);

        // Calculate Totals
        total += amount;

        if (date.isAfter(startOfMonth)) {
          month += amount;
        }

        // Simple week check (resetting on Monday)
        if (date.isAfter(startOfWeek.subtract(const Duration(seconds: 1)))) {
          week += amount;
        }

        if (date.isAfter(startOfDay)) {
          today += amount;
        }
      }

      // Sort by date descending (newest first)
      validDocs.sort((a, b) {
        Timestamp tA = a['created_at'];
        Timestamp tB = b['created_at'];
        return tB.compareTo(tA);
      });

      if (mounted) {
        setState(() {
          _totalEarnings = total;
          _monthlyEarnings = month;
          _weeklyEarnings = week;
          _todayEarnings = today;
          _transactions = validDocs;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching earnings: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accentYellow),
      );
    }

    final currencyFormat = NumberFormat.simpleCurrency(
      name: 'USD',
    ); // Change to 'INR' or symbol as needed

    return Column(
      children: [
        // Scrollable Content
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchEarningsData,
            color: AppColors.accentYellow,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Total Earnings Card
                    _buildTotalEarningsCard(currencyFormat),
                    const SizedBox(height: 20),

                    // Today / This Week Summary Row
                    _buildSummaryRow(currencyFormat),
                    const SizedBox(height: 25),

                    // Recent Transactions Title
                    const Text(
                      'Recent Transactions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Transactions List
                    if (_transactions.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Center(
                          child: Text(
                            "No transactions yet.",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _transactions.length,
                        itemBuilder: (context, index) {
                          final data =
                              _transactions[index].data()
                                  as Map<String, dynamic>;
                          final docId = _transactions[index].id;
                          final date = (data['created_at'] as Timestamp)
                              .toDate();
                          final amount = (data['price'] as num).toDouble();

                          // Format Date: "Oct 29, 2:30 PM"
                          final dateStr = DateFormat(
                            'MMM d, h:mm a',
                          ).format(date);
                          // Short ID: "1234" (Taking last 4 chars of doc ID for display)
                          final shortId = docId.length > 4
                              ? docId.substring(docId.length - 4)
                              : docId;

                          return _buildTransactionItem(
                            rideNumber: shortId,
                            dateTime: dateStr,
                            amount: amount.toStringAsFixed(2),
                          );
                        },
                      ),

                    const SizedBox(height: 50), // Bottom padding
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- Helper Widgets ---

  Widget _buildTotalEarningsCard(NumberFormat formatter) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30.0),
      decoration: BoxDecoration(
        color: AppColors.lightYellowBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            'Total Earnings',
            style: TextStyle(color: AppColors.secondaryText, fontSize: 16),
          ),
          const SizedBox(height: 10),
          Text(
            formatter.format(_totalEarnings),
            style: const TextStyle(
              color: AppColors.primaryText,
              fontSize: 40,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'This Month: ${formatter.format(_monthlyEarnings)}',
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(NumberFormat formatter) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'Today',
            amount: formatter.format(_todayEarnings),
            amountColor: AppColors.positiveGreen,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildSummaryCard(
            title: 'This Week',
            amount: formatter.format(_weeklyEarnings),
            amountColor: AppColors.infoBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String amount,
    required Color amountColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 25.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            amount,
            style: TextStyle(
              color: amountColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem({
    required String rideNumber,
    required String dateTime,
    required String amount,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ride #$rideNumber',
                style: const TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                dateTime,
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Text(
            '\$$amount', // You can remove the $ if you pass the formatted string
            style: const TextStyle(
              color: AppColors.positiveGreen,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
