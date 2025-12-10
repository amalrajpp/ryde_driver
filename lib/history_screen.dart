import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Using DefaultTabController for the 3 tabs
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFF01221D), // Your App Theme Color
          title: const Text(
            "History",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            // Custom Tab Bar Container to get the White background effect
            Container(
              color: Colors.white,
              child: const TabBar(
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Color(0xFF01221D),
                indicatorWeight: 3,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                tabs: [
                  Tab(text: "Completed"),
                  Tab(text: "Upcoming"),
                  Tab(text: "Cancelled"),
                ],
              ),
            ),
            // The content of the tabs
            Expanded(
              child: TabBarView(
                children: [
                  _buildEmptyState(), // Completed Tab
                  _buildEmptyState(), // Upcoming Tab
                  _buildEmptyState(), // Cancelled Tab
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration
          // Note: In a real app, use Image.asset('assets/your_image.png')
          // Here I am using an Icon/Container placeholder to mimic the visual
          Container(
            height: 200,
            width: 200,
            decoration: BoxDecoration(
              color: Colors.grey[100], // Placeholder background
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.manage_search_rounded, // Placeholder icon
              size: 100,
              color: Colors.blue[300],
            ),
          ),
          const SizedBox(height: 30),

          // Main Text
          const Text(
            "No History Available",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 10),

          // Subtitle Text
          const Text(
            "Make new booking to view it\nhere.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
          ),
          // Pushing content up slightly to match screenshot
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
