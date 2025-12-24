import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Selected date for viewing earnings
  DateTime _selectedDate = DateTime.now();

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
    final startOfWeek = _getStartOfWeek(_selectedDate);
    final endOfWeek = _getEndOfWeek(_selectedDate);

    final dateFormat = DateFormat('dd-MMM-yy');
    final dateRangeString =
        "${dateFormat.format(startOfWeek)} - ${dateFormat.format(endOfWeek)}";

    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('booking').snapshots(),
        builder: (context, snapshot) {
          double weeklyEarnings = 0.0;
          int completedTrips = 0;

          // Daily stats for selected date
          double dailyEarnings = 0.0;
          int dailyTrips = 0;
          DateTime selectedDateOnly = DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
          );

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
                DateTime tripDateOnly = DateTime(
                  tripDate.year,
                  tripDate.month,
                  tripDate.day,
                );

                // Check if the trip date is within the current week (inclusive)
                if (tripDate.isAfter(
                      startOfWeek.subtract(const Duration(seconds: 1)),
                    ) &&
                    tripDate.isBefore(
                      endOfWeek.add(const Duration(seconds: 1)),
                    )) {
                  // --- 4. Price Calculation ---
                  final price = data['price'];
                  double tripPrice = 0.0;
                  if (price is num) {
                    tripPrice = price.toDouble();
                  } else if (price is String) {
                    tripPrice = double.tryParse(price) ?? 0.0;
                  }

                  weeklyEarnings += tripPrice;
                  completedTrips++;

                  // Check if trip is on selected date
                  if (tripDateOnly.year == selectedDateOnly.year &&
                      tripDateOnly.month == selectedDateOnly.month &&
                      tripDateOnly.day == selectedDateOnly.day) {
                    dailyEarnings += tripPrice;
                    dailyTrips++;
                  }
                }
              }
            }
          }

          return Stack(
            children: [
              // Background Design - Dark section at top
              Container(
                height: 340,
                decoration: const BoxDecoration(color: Color(0xFF01221D)),
              ),

              // Scrollable Content
              SafeArea(
                child: SingleChildScrollView(
                  child: Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        // Dark header section
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.only(top: 16, bottom: 20),
                          decoration: const BoxDecoration(
                            color: Color(0xFF01221D),
                          ),
                          child: Column(
                            children: [
                              // Title
                              const Text(
                                "Weekly Earnings",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Earnings Value Card
                              Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                  horizontal: 24,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "₹ ",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 28,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          weeklyEarnings.toStringAsFixed(2),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 42,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: -1,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "$completedTrips trips completed",
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Date Range with Navigation
                              Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 20.0,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Previous Week Button
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(8),
                                        onTap: () {
                                          setState(() {
                                            _selectedDate = _selectedDate
                                                .subtract(
                                                  const Duration(days: 7),
                                                );
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          child: const Icon(
                                            Icons.chevron_left_rounded,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Date Range (Tap to pick date)
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () async {
                                          final DateTime?
                                          picked = await showDatePicker(
                                            context: context,
                                            initialDate: _selectedDate,
                                            firstDate: DateTime(2020),
                                            lastDate: DateTime.now(),
                                            builder: (context, child) {
                                              return Theme(
                                                data: Theme.of(context).copyWith(
                                                  colorScheme:
                                                      const ColorScheme.light(
                                                        primary: Color(
                                                          0xFF01221D,
                                                        ),
                                                        onPrimary: Colors.white,
                                                        onSurface: Colors.black,
                                                      ),
                                                ),
                                                child: child!,
                                              );
                                            },
                                          );
                                          if (picked != null) {
                                            setState(() {
                                              _selectedDate = picked;
                                            });
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.calendar_today_rounded,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                dateRangeString,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Next Week Button (disabled if current week)
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(8),
                                        onTap:
                                            _getStartOfWeek(
                                              _selectedDate,
                                            ).isBefore(
                                              _getStartOfWeek(DateTime.now()),
                                            )
                                            ? () {
                                                setState(() {
                                                  _selectedDate = _selectedDate
                                                      .add(
                                                        const Duration(days: 7),
                                                      );
                                                });
                                              }
                                            : null,
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          child: Icon(
                                            Icons.chevron_right_rounded,
                                            color:
                                                _getStartOfWeek(
                                                  _selectedDate,
                                                ).isBefore(
                                                  _getStartOfWeek(
                                                    DateTime.now(),
                                                  ),
                                                )
                                                ? Colors.white
                                                : Colors.white.withOpacity(0.3),
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Calendar Widget
                              Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: _buildCalendarDays(startOfWeek),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Daily Stats for Selected Date
                              Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      DateFormat(
                                        'EEEE, MMM dd, yyyy',
                                      ).format(_selectedDate),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF01221D),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.04),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              children: [
                                                Icon(
                                                  Icons.local_taxi_rounded,
                                                  color: const Color(
                                                    0xFF01221D,
                                                  ),
                                                  size: 32,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  "$dailyTrips",
                                                  style: const TextStyle(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF01221D),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  "Rides",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.04),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              children: [
                                                Icon(
                                                  Icons.currency_rupee_rounded,
                                                  color: const Color(
                                                    0xFF01221D,
                                                  ),
                                                  size: 32,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  "₹${dailyEarnings.toStringAsFixed(0)}",
                                                  style: const TextStyle(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF01221D),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  "Earnings",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Stats Card (Trips, Wallet, Cash) - White section
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
                              const SizedBox(height: 24),

                              // ===== PAYMENT WITHDRAWAL BUTTON =====
                              const SizedBox(height: 24),

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
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildCalendarDays(DateTime startOfWeek) {
    List<String> days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    List<Widget> calendarWidgets = [];
    DateTime today = DateTime.now();
    DateTime todayDateOnly = DateTime(today.year, today.month, today.day);

    for (int i = 0; i < 7; i++) {
      DateTime currentDay = startOfWeek.add(Duration(days: i));
      DateTime currentDayDateOnly = DateTime(
        currentDay.year,
        currentDay.month,
        currentDay.day,
      );

      bool isSelectedDay =
          currentDay.day == _selectedDate.day &&
          currentDay.month == _selectedDate.month &&
          currentDay.year == _selectedDate.year;

      // Check if the day is in the future
      bool isFutureDay = currentDayDateOnly.isAfter(todayDateOnly);

      calendarWidgets.add(
        GestureDetector(
          onTap: isFutureDay
              ? null
              : () {
                  setState(() {
                    _selectedDate = currentDay;
                  });
                },
          child: CalendarDay(
            day: days[i],
            date: currentDay.day.toString().padLeft(2, '0'),
            isSelected: isSelectedDay,
            isFutureDay: isFutureDay,
          ),
        ),
      );
    }
    return calendarWidgets;
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
  final bool isFutureDay;

  const CalendarDay({
    super.key,
    required this.day,
    required this.date,
    this.isSelected = false,
    this.isFutureDay = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          day,
          style: TextStyle(
            fontSize: 14,
            color: isFutureDay ? Colors.grey[400] : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? const Color(0xFF01221D) : Colors.transparent,
            border: Border.all(
              color: isFutureDay ? Colors.grey[300]! : Colors.grey,
            ),
          ),
          child: Center(
            child: Text(
              date,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : isFutureDay
                    ? Colors.grey[400]
                    : Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
