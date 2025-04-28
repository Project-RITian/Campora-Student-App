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
        color: Colors.white, // Flat white background
        child: Center(
          child: Container(
            width: double.infinity,
            margin:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
            child: Card(
              elevation: 0, // No shadow
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
                side: BorderSide(
                    color: Colors.grey.shade300, width: 1), // Thin border
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(12.0), // Reduced padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min, // Compact size
                  children: [
                    // PIN Section
                    Text(
                      pin,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 12), // Reduced spacing
                    // Order Details
                    Text(
                      '$type Order',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow('Total Cost', '$totalCost RITZ'),
                    if (timestamp != null)
                      _buildDetailRow(
                          'Date', timestamp.toLocal().toString().split('.')[0]),
                    if (type == 'canteen') ...[
                      _buildDetailRow('Takeaway', isTakeaway ? 'Yes' : 'No'),
                      const SizedBox(height: 8),
                      const Text(
                        'Items:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ...items.map((item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Text(
                              '${item['name']} x${item['quantity']} (${item['price']} RITZ each)',
                              style: const TextStyle(fontSize: 14),
                            ),
                          )),
                    ],
                    if (type == 'arcade') ...[
                      if (xeroxDetails != null) ...[
                        const Text(
                          'Xerox Details:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildDetailRow(
                            'File', xeroxDetails['fileName'] ?? 'N/A'),
                        _buildDetailRow('Copies',
                            xeroxDetails['copies']?.toString() ?? '0'),
                        _buildDetailRow(
                            'Print Type', xeroxDetails['printType'] ?? 'N/A'),
                        _buildDetailRow(
                            'Print Side', xeroxDetails['printSide'] ?? 'N/A'),
                        if (xeroxDetails['customInstructions']?.isNotEmpty ??
                            false)
                          _buildDetailRow('Instructions',
                              xeroxDetails['customInstructions']),
                      ],
                      if (items.isNotEmpty) ...[
                        const Text(
                          'Stationery Items:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ...items.map((item) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 2.0),
                              child: Text(
                                '${item['name']} x${item['quantity']} (${item['price']} RITZ each)',
                                style: const TextStyle(fontSize: 14),
                              ),
                            )),
                      ],
                    ],
                    const SizedBox(height: 12),
                    // Perforated Bottom with CustomPaint
                    SizedBox(
                      height: 16,
                      child: CustomPaint(
                        painter: DashedLinePainter(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0), // Reduced padding
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: Colors.black),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter for Dashed Line
class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade400 // Lighter gray for minimalism
      ..strokeWidth = 1.0 // Thinner line
      ..style = PaintingStyle.stroke;

    const dashWidth = 8.0; // Slightly smaller dashes
    const dashSpace = 4.0; // Smaller gaps
    double startX = 0.0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
