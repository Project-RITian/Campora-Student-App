import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/custom_navigation_drawer.dart';

class PurchaseDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> purchase;

  const PurchaseDetailsScreen({super.key, required this.purchase});

  @override
  Widget build(BuildContext context) {
    final type = purchase['type'] ?? 'Unknown';
    final pin = purchase['pin'] ?? 'N/A';
    final totalCost = purchase['totalCost']?.toStringAsFixed(2) ?? '0.00';
    final timestamp = (purchase['timestamp'] as Timestamp?)?.toDate();
    final isTakeaway = purchase['isTakeaway'] ?? false;
    final items = (purchase['items'] as List<dynamic>?) ?? [];
    final xeroxDetails = purchase['xeroxDetails'] as Map<String, dynamic>?;

    return Scaffold(
      appBar: CustomNavigationDrawer.buildAppBar(context, 'Order Details'),
      drawer: const CustomNavigationDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0C4D83), Color(0xFF64B5F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  Text(
                    '$type Order Details',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0C4D83),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow('PIN', pin),
                  _buildDetailRow('Total Cost', '$totalCost RITZ'),
                  if (timestamp != null)
                    _buildDetailRow('Date', timestamp.toString()),
                  const SizedBox(height: 16),
                  if (type == 'canteen') ...[
                    _buildDetailRow('Takeaway', isTakeaway ? 'Yes' : 'No'),
                    const Text(
                      'Items:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...items.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(
                            '${item['name']} x${item['quantity']} (${item['price']} RITZ each)',
                            style: const TextStyle(fontSize: 16),
                          ),
                        )),
                  ],
                  if (type == 'arcade') ...[
                    if (xeroxDetails != null) ...[
                      const Text(
                        'Xerox Details:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                          'File', xeroxDetails['fileName'] ?? 'N/A'),
                      _buildDetailRow(
                          'Copies', xeroxDetails['copies']?.toString() ?? '0'),
                      _buildDetailRow(
                          'Print Type', xeroxDetails['printType'] ?? 'N/A'),
                      _buildDetailRow(
                          'Print Side', xeroxDetails['printSide'] ?? 'N/A'),
                      if (xeroxDetails['customInstructions']?.isNotEmpty ??
                          false)
                        _buildDetailRow(
                            'Instructions', xeroxDetails['customInstructions']),
                    ],
                    if (items.isNotEmpty) ...[
                      const Text(
                        'Stationery Items:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...items.map((item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Text(
                              '${item['name']} x${item['quantity']} (${item['price']} RITZ each)',
                              style: const TextStyle(fontSize: 16),
                            ),
                          )),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
