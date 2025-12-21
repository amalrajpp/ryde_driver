import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:ryde/payment_module/helpers/payment_integration.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Helper: Start of Week (Monday)
  DateTime _getStartOfWeek(DateTime date) {
    final safeDate = DateTime(date.year, date.month, date.day);
    return safeDate.subtract(Duration(days: safeDate.weekday - 1));
  }

  // Helper: End of Week (Sunday)
  DateTime _getEndOfWeek(DateTime date) {
    final start = _getStartOfWeek(date);
    return start.add(
      const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
    );
  }

  // Helper: Parse Date from Firestore (Timestamp or String)
  DateTime? _parseDate(dynamic dateData) {
    if (dateData == null) return null;
    try {
      if (dateData is Timestamp) {
        // Convert Firestore Timestamp to local device time
        return dateData.toDate().toLocal();
      }
      if (dateData is String) {
        return DateTime.tryParse(dateData)?.toLocal();
      }
    } catch (e) {
      debugPrint("Date parse error: $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final now = DateTime.now();
    final startOfWeek = _getStartOfWeek(now);
    final endOfWeek = _getEndOfWeek(now);

    final dateFormat = DateFormat('dd-MMM-yy');
    final dateRangeString =
        "${dateFormat.format(startOfWeek)} - ${dateFormat.format(endOfWeek)}";

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('booking').snapshots(),
        builder: (context, snapshot) {
          double weeklyEarnings = 0.0;
          int completedTrips = 0;

          if (snapshot.hasData && user != null) {
            final docs = snapshot.data!.docs;

            for (var doc in docs) {
              final data = doc.data() as Map<String, dynamic>;

              // --- 1. Driver ID Check ---
              // Check for driver_id at the top level of the booking document
              final driverId = data['driver_id']?.toString();

              // If the ID doesn't match current user, skip this trip
              if (driverId != user.uid) continue;

              // --- 2. Status Check ---
              final status = data['status'] as String?;
              if (status?.toLowerCase() != 'completed') continue;

              // --- 3. Date Check (Weekly) ---
              // Prioritize 'completed_at' (from Screenshot 4), fallback to 'created_at'
              final dynamic dateVal =
                  data['completed_at'] ??
                  data['created_at'] ??
                  data['started_at'];
              final tripDate = _parseDate(dateVal);

              if (tripDate != null) {
                // Check if the trip date is within the current week (inclusive)
                if (tripDate.isAfter(
                      startOfWeek.subtract(const Duration(seconds: 1)),
                    ) &&
                    tripDate.isBefore(
                      endOfWeek.add(const Duration(seconds: 1)),
                    )) {
                  // --- 4. Price Calculation ---
                  final price = data['price'];
                  if (price is num) {
                    weeklyEarnings += price.toDouble();
                  } else if (price is String) {
                    weeklyEarnings += double.tryParse(price) ?? 0.0;
                  }

                  completedTrips++;
                }
              }
            }
          }

          return Stack(
            children: [
              // Background Design
              Column(
                children: [
                  Container(height: 300, color: const Color(0xFF01221D)),
                  Expanded(child: Container(color: Colors.white)),
                ],
              ),

              // Scrollable Content
              SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // Title
                      const Text(
                        "Weekly Earnings",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Earnings Value
                      Text(
                        "₹ ${weeklyEarnings.toStringAsFixed(2)}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Date Range
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              dateRangeString,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const Text(
                              "Login : 0 Mins",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 15),

                      // Calendar Widget
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.symmetric(
                          vertical: 20,
                          horizontal: 15,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: _buildCalendarDays(startOfWeek),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Stats Card (Trips, Wallet, Cash)
                      Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 25),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    spreadRadius: 2,
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: IntrinsicHeight(
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildStatItem("Trips $completedTrips"),
                                    const VerticalDivider(
                                      color: Colors.grey,
                                      thickness: 1,
                                    ),
                                    _buildStatItem(
                                      "Wallet ₹ ${weeklyEarnings.toStringAsFixed(0)}",
                                    ),
                                    const VerticalDivider(
                                      color: Colors.grey,
                                      thickness: 1,
                                    ),
                                    _buildStatItem("Cash ₹ 0"),
                                  ],
                                ),
                              ),
                            ),

                            // ===== PAYMENT WITHDRAWAL BUTTON =====
                            const SizedBox(height: 20),
                            if (weeklyEarnings > 0)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                child: PaymentIntegration.buildEarningsPaymentButton(
                                  context: context,
                                  earningsAmount: weeklyEarnings,
                                  onPressed: () async {
                                    final success =
                                        await PaymentIntegration.showPaymentScreenWithMock(
                                          context: context,
                                          amount: weeklyEarnings,
                                          title: 'Withdraw Earnings',
                                          primaryColor: const Color(0xFF01221D),
                                        );

                                    if (success == true && mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Withdrawal initiated successfully!',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),

                            // Visual Spacers for Graph Area
                            const SizedBox(height: 100),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40.0,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildGraphLabel("M"),
                                  _buildGraphLabel("T"),
                                  _buildGraphLabel("W"),
                                  _buildGraphLabel("T"),
                                  _buildGraphLabel("F"),
                                  _buildGraphLabel("S"),
                                  _buildGraphLabel("S"),
                                ],
                              ),
                            ),
                            const SizedBox(height: 50),
                          ],
                        ),
                      ),

                      // Recent Transactions List
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            const Text(
                              "Recent Transactions",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 15),
                            _buildTransactionsList(snapshot, user),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      /*  bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            label: "Earnings",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Accounts"),
        ],
      ),*/
    );
  }

  List<Widget> _buildCalendarDays(DateTime startOfWeek) {
    List<String> days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    List<Widget> calendarWidgets = [];
    final today = DateTime.now();

    for (int i = 0; i < 7; i++) {
      DateTime currentDay = startOfWeek.add(Duration(days: i));
      bool isToday =
          currentDay.day == today.day && currentDay.month == today.month;

      calendarWidgets.add(
        CalendarDay(
          day: days[i],
          date: currentDay.day.toString().padLeft(2, '0'),
          isSelected: isToday,
        ),
      );
    }
    return calendarWidgets;
  }

  Widget _buildStatItem(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildGraphLabel(String day) {
    return Column(
      children: [
        Container(width: 30, height: 1, color: Colors.grey[700]),
        const SizedBox(height: 10),
        Text(day, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildTransactionsList(
    AsyncSnapshot<QuerySnapshot> snapshot,
    User? user,
  ) {
    if (user == null) {
      return const Center(child: Text("Not authenticated"));
    }

    if (!snapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    final docs = snapshot.data!.docs;
    final transactions = <Map<String, dynamic>>[];

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;

      // Filter by driver ID (top-level field in booking collection)
      final driverId = data['driver_id']?.toString();
      if (driverId != user.uid) continue;

      // Filter by status (completed)
      final status = data['status'] as String?;
      if (status?.toLowerCase() != 'completed') continue;

      // Get trip amount and date
      final price = data['price'];
      final amount = price is num
          ? price.toDouble()
          : (price is String ? double.tryParse(price) ?? 0.0 : 0.0);

      final dynamic dateVal =
          data['completed_at'] ?? data['created_at'] ?? data['started_at'];
      final tripDate = _parseDate(dateVal);

      if (amount > 0 && tripDate != null) {
        transactions.add({
          'amount': amount,
          'date': tripDate,
          'pickupLocation': data['pickup'] ?? 'Pickup',
          'dropoffLocation': data['dropoff'] ?? 'Dropoff',
          'docId': doc.id,
        });
      }
    }

    // Sort by date (newest first)
    transactions.sort(
      (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),
    );

    if (transactions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20.0),
        child: Text("No completed trips", style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      children: transactions.map((txn) {
        final dateFormat = DateFormat('dd MMM, HH:mm');
        final formattedDate = dateFormat.format(txn['date'] as DateTime);
        final amount = txn['amount'] as double;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${txn['pickupLocation']} → ${txn['dropoffLocation']}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              // Amount
              Text(
                "+₹ ${amount.toStringAsFixed(2)}",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class CalendarDay extends StatelessWidget {
  final String day;
  final String date;
  final bool isSelected;

  const CalendarDay({
    super.key,
    required this.day,
    required this.date,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(day, style: const TextStyle(fontSize: 14, color: Colors.black87)),
        const SizedBox(height: 8),
        Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? Colors.grey[600] : Colors.transparent,
            border: Border.all(color: Colors.grey),
          ),
          child: Center(
            child: Text(
              date,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
