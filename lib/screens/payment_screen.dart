import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/stationery_item.dart';
import '../models/food_item.dart';
import '../widgets/custom_navigation_drawer.dart';
import 'payment_success_screen.dart';
import 'ritz_purchase_screen.dart';

class PaymentScreen extends StatefulWidget {
  final File? file;
  final int copies;
  final bool isColor;
  final String printSide;
  final String customInstructions;
  final Map<int, int> stationeryCart;
  final List<StationeryItem> stationeryItems;
  final Map<String, int> foodCart;
  final List<FoodItem> foodItems;
  final bool isTakeaway;

const PaymentScreen({
    super.key,
    this.file,
    required this.copies,
    required this.isColor,
    required this.printSide,
    required this.customInstructions,
    required this.stationeryCart,
    required this.stationeryItems,
    required this.foodCart, // Now accepts Map<String, int>
    required this.foodItems,
    required this.isTakeaway,
  });

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _buttonController;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.bounceOut),
    );
  }

  @override
  void dispose() {
    _buttonController.dispose();
    super.dispose();
  }

  double _calculateTotal() {
    double total = 0;
    // Handle xerox costs
    if (widget.file != null) {
      total += widget.copies * (widget.isColor ? 2.0 : 1.0); // RITZ per copy
      if (widget.printSide == 'Single Sided') {
        total *= 0.9; // 10% discount for single-sided
      }
    }
    // Handle stationery items
    widget.stationeryCart.forEach((id, qty) {
      final item = widget.stationeryItems.firstWhere((item) => item.id == id);
      total += item.price * qty;
    });
    // Handle food items
    widget.foodCart.forEach((id, qty) {
      final item = widget.foodItems.firstWhere((item) => item.id == id);
      total += item.price * qty;
    });
    // Add takeaway charge
    if (widget.isTakeaway) {
      total += 3.0; // Extra 3 RITZ for takeaway
    }
    return total;
  }

  Future<bool> _processPayment() async {
    final user = fb_auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to make a payment')),
      );
      return false;
    }

    final total = _calculateTotal();
    try {
      final balanceRef =
          FirebaseFirestore.instance.collection('user_balances').doc(user.uid);
      return await FirebaseFirestore.instance
          .runTransaction((transaction) async {
        final snapshot = await transaction.get(balanceRef);
        double currentBalance = 0.0;
        if (snapshot.exists) {
          currentBalance =
              (snapshot.data()?['balance'] as num?)?.toDouble() ?? 0.0;
        }

        if (currentBalance < total) {
          return false; // Insufficient balance
        }

        final newBalance = currentBalance - total;
        transaction.set(
            balanceRef, {'balance': newBalance}, SetOptions(merge: true));
        return true;
      });
    } catch (e) {
      print('Error processing payment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error processing payment')),
      );
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _calculateTotal();
    final user = fb_auth.FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: CustomNavigationDrawer.buildAppBar(context, 'Payment'),
      drawer: const CustomNavigationDrawer(),
      body: Container(
        decoration: const BoxDecoration(),
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Summary',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Display xerox details
                  if (widget.file != null)
                    AnimatedOpacity(
                      opacity: 1.0,
                      duration: const Duration(milliseconds: 500),
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        margin: const EdgeInsets.only(bottom: 16.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Xerox Details',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0C4D83),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Copies: ${widget.copies} (${widget.isColor ? 'Color' : 'B/W'})',
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.black87),
                            ),
                            Text(
                              'Print Side: ${widget.printSide}',
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.black87),
                            ),
                            if (widget.customInstructions.isNotEmpty)
                              Text(
                                'Instructions: ${widget.customInstructions}',
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.black87),
                              ),
                          ],
                        ),
                      ),
                    ),
                  // Display stationery items
                  if (widget.stationeryCart.isNotEmpty)
                    AnimatedOpacity(
                      opacity: 1.0,
                      duration: const Duration(milliseconds: 500),
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        margin: const EdgeInsets.only(bottom: 16.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Stationery Items',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0C4D83),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...widget.stationeryCart.entries.map((entry) {
                              final item = widget.stationeryItems
                                  .firstWhere((i) => i.id == entry.key);
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${item.name} (${entry.value}x)',
                                      style: const TextStyle(
                                          fontSize: 16, color: Colors.black87),
                                    ),
                                    Text(
                                      '${item.price * entry.value} RITZ',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.teal[300],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  // Display food items
                  if (widget.foodCart.isNotEmpty)
                    AnimatedOpacity(
                      opacity: 1.0,
                      duration: const Duration(milliseconds: 500),
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        margin: const EdgeInsets.only(bottom: 16.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Food Items',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0C4D83),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...widget.foodCart.entries.map((entry) {
                              final item = widget.foodItems
                                  .firstWhere((i) => i.id == entry.key);
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${item.name} (${entry.value}x)',
                                      style: const TextStyle(
                                          fontSize: 16, color: Colors.black87),
                                    ),
                                    Text(
                                      '${item.price * entry.value} RITZ',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.teal[300],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  // Takeaway Option Display
                  if (widget.isTakeaway)
                    AnimatedOpacity(
                      opacity: 1.0,
                      duration: const Duration(milliseconds: 500),
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        margin: const EdgeInsets.only(bottom: 16.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Takeaway Charge',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF0C4D83),
                              ),
                            ),
                            Text(
                              '+3 RITZ',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.teal,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Total and Balance
                  StreamBuilder<DocumentSnapshot>(
                    stream: user != null
                        ? FirebaseFirestore.instance
                            .collection('user_balances')
                            .doc(user.uid)
                            .snapshots()
                        : null,
                    builder: (context, snapshot) {
                      double balance = 0.0;
                      if (snapshot.hasData && snapshot.data!.exists) {
                        balance =
                            (snapshot.data!['balance'] as num?)?.toDouble() ??
                                0.0;
                      }

                      return Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(16.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0C4D83),
                                  ),
                                ),
                                Text(
                                  '$total RITZ',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.teal[300],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Available Balance',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.black87),
                                ),
                                Text(
                                  '$balance RITZ',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: balance >= total
                                        ? Colors.green
                                        : Colors.redAccent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 80), // Space for floating buttons
                ],
              ),
            ),
            Positioned(
              bottom: 16.0,
              right: 16.0,
              child: GestureDetector(
                onTap: () async {
                  final success = await _processPayment();
                  if (success) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const PaymentSuccessScreen()),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Insufficient RITZ balance'),
                        backgroundColor: Colors.redAccent,
                        action: SnackBarAction(
                          label: 'Buy RITZ',
                          textColor: Colors.white,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const RitzPurchaseScreen()),
                            );
                          },
                        ),
                      ),
                    );
                  }
                },
                child: AnimatedBuilder(
                  animation: _buttonScaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _buttonScaleAnimation.value,
                      child: Container(
                        height: 60,
                        width: 60,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF0C4D83), Color(0xFF64B5F6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.payment,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              bottom: 16.0,
              left: 16.0,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const RitzPurchaseScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12.0),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.orange, Colors.orangeAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Buy More RITZ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
