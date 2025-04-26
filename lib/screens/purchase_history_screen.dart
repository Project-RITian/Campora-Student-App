import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../widgets/custom_navigation_drawer.dart';
import 'purchase_details_screen.dart';

class PurchaseHistoryScreen extends StatefulWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  _PurchaseHistoryScreenState createState() => _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState extends State<PurchaseHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: CustomNavigationDrawer.buildAppBar(context, 'Purchase History'),
        drawer: const CustomNavigationDrawer(),
        body: const Center(
            child: Text('Please sign in to view purchase history')),
      );
    }

    return Scaffold(
      appBar: CustomNavigationDrawer.buildAppBar(context, 'Purchase History'),
      drawer: const CustomNavigationDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0C4D83), Color(0xFF64B5F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('purchases')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No purchases found'));
            }

            final purchases = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: purchases.length,
              itemBuilder: (context, index) {
                final purchase =
                    purchases[index].data() as Map<String, dynamic>;
                final type = purchase['type'] ?? 'Unknown';
                final pin = purchase['pin'] ?? 'N/A';
                final totalCost =
                    purchase['totalCost']?.toStringAsFixed(2) ?? '0.00';
                final timestamp =
                    (purchase['timestamp'] as Timestamp?)?.toDate();
                final isTakeaway = purchase['isTakeaway'] ?? false;
                final items = (purchase['items'] as List<dynamic>?) ?? [];
                final xeroxDetails =
                    purchase['xeroxDetails'] as Map<String, dynamic>?;

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PurchaseDetailsScreen(
                          purchase: purchase,
                        ),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$type Purchase (PIN: $pin)',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0C4D83),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Total: $totalCost RITZ'),
                          if (type == 'canteen') ...[
                            Text('Takeaway: ${isTakeaway ? "Yes" : "No"}'),
                            const SizedBox(height: 8),
                            Text(
                              'Items: ${items.map((item) => "${item['name']} x${item['quantity']}").join(", ")}',
                            ),
                          ],
                          if (type == 'arcade' && xeroxDetails != null) ...[
                            Text('File: ${xeroxDetails['fileName'] ?? "N/A"}'),
                            Text('Copies: ${xeroxDetails['copies'] ?? 0}'),
                          ],
                          if (items.isNotEmpty && type == 'arcade')
                            Text(
                              'Stationery: ${items.map((item) => "${item['name']} x${item['quantity']}").join(", ")}',
                            ),
                          const SizedBox(height: 8),
                          if (timestamp != null)
                            Text(
                              'Date: ${timestamp.toString()}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
