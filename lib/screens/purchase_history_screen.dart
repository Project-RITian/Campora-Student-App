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
                final pin = purchase['pin']?.toString() ?? 'N/A';
                final totalCost =
                    (purchase['totalCost'] as num?)?.toStringAsFixed(2) ??
                        '0.00';
                final timestamp =
                    (purchase['timestamp'] as Timestamp?)?.toDate();
                final isTakeaway = purchase['isTakeaway'] as bool? ?? false;
                final items = (purchase['items'] as List<dynamic>?)
                        ?.cast<Map<String, dynamic>>() ??
                    [];
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '$type Purchase (PIN: $pin)',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0C4D83),
                                ),
                              ),
                              Text(
                                'Total: $totalCost RITZ',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.teal[300],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (items.isNotEmpty) ...[
                            const Text(
                              'Items:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0C4D83),
                              ),
                            ),
                            const SizedBox(height: 4),
                            ...items.map((item) {
                              final itemName =
                                  item['name']?.toString() ?? 'Unknown';
                              final itemPrice =
                                  (item['price'] as num?)?.toStringAsFixed(2) ??
                                      '0.00';
                              final itemQuantity =
                                  (item['quantity'] as num?)?.toString() ?? '0';
                              final itemType =
                                  item['type']?.toString() ?? 'Unknown';
                              final itemTotal = (item['price'] as num? ??
                                      0 * (item['quantity'] as num? ?? 0))
                                  .toStringAsFixed(2);
                              return Padding(
                                padding:
                                    const EdgeInsets.only(left: 8.0, top: 2.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '$itemType: $itemName x$itemQuantity',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    Text(
                                      '$itemTotal RITZ',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.teal[300],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                          if (type == 'arcade' && xeroxDetails != null) ...[
                            const SizedBox(height: 8),
                            const Text(
                              'Xerox Details:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0C4D83),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'File: ${xeroxDetails['fileName']?.toString() ?? 'N/A'}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    'Copies: ${(xeroxDetails['copies'] as num?)?.toString() ?? '0'}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    'Print Type: ${xeroxDetails['printType'] == 'Color' ? 'Color' : 'B/W'}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    'Print Side: ${xeroxDetails['printSide']?.toString() ?? 'N/A'}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  if (xeroxDetails['customInstructions'] !=
                                          null &&
                                      (xeroxDetails['customInstructions']
                                              as String)
                                          .isNotEmpty)
                                    Text(
                                      'Instructions: ${xeroxDetails['customInstructions']}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                ],
                              ),
                            ),
                          ],
                          if (type == 'canteen') ...[
                            const SizedBox(height: 8),
                            Text(
                              'Takeaway: ${isTakeaway ? "Yes" : "No"}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF0C4D83),
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          if (timestamp != null)
                            Text(
                              'Date: ${timestamp.toLocal().toString().split('.')[0]}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
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
