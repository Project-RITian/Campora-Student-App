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
    required this.foodCart,
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
    if (widget.file != null) {
      total += widget.copies * (widget.isColor ? 2.0 : 1.0);
      if (widget.printSide == 'Single Sided') {
        total *= 0.9;
      }
    }
    widget.stationeryCart.forEach((id, qty) {
      final item = widget.stationeryItems.firstWhere((item) => item.id == id);
      total += item.price * qty;
    });
    widget.foodCart.forEach((id, qty) {
      final item = widget.foodItems.firstWhere((item) => item.id == id);
      total += item.price * qty;
    });
    if (widget.isTakeaway) {
      total += 3.0;
    }
    return total;
  }

  Future<bool> _processPayment() async {
    final user = fb_auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to make a payment')),
        );
      }
      debugPrint('No user logged in');
      return false;
    }

    debugPrint('User authenticated: ${user.uid}, Email: ${user.email}');
    final total = _calculateTotal();
    debugPrint('Total to deduct: $total RITZ');
    debugPrint('Food cart before payment: ${widget.foodCart}');
    debugPrint('Stationery cart before payment: ${widget.stationeryCart}');

    try {
      final balanceRef =
          FirebaseFirestore.instance.collection('user_balances').doc(user.uid);

      // Initialize balance document if it doesn't exist
      final balanceSnapshot = await balanceRef.get();
      if (!balanceSnapshot.exists ||
          balanceSnapshot.data()?['balance'] == null) {
        await balanceRef.set({'balance': 965.0}, SetOptions(merge: true));
        debugPrint(
            'Initialized/Updated balance to 965.0 RITZ for user: ${user.uid}');
        // Force StreamBuilder to refresh
        await Future.delayed(Duration(milliseconds: 100));
      }

      bool success = false;
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(balanceRef);
        if (!snapshot.exists || snapshot.data()?['balance'] == null) {
          throw Exception(
              'Balance document missing or invalid after initialization');
        }

        final currentBalance = (snapshot.data()!['balance'] as num).toDouble();
        debugPrint('Current Firestore balance: $currentBalance RITZ');

        if (currentBalance < total) {
          debugPrint('Insufficient balance: $currentBalance < $total');
          return;
        }

        final newBalance = currentBalance - total;
        debugPrint('Deducting $total RITZ, new balance: $newBalance RITZ');

        transaction.update(balanceRef, {'balance': newBalance});

        final transactionRef =
            FirebaseFirestore.instance.collection('transactions').doc();
        transaction.set(transactionRef, {
          'userId': user.uid,
          'amount': total,
          'type': 'purchase',
          'items': {
            'food': widget.foodCart,
            'stationery': widget.stationeryCart,
            'xerox': widget.file != null
                ? {
                    'copies': widget.copies,
                    'isColor': widget.isColor,
                    'side': widget.printSide,
                  }
                : null,
          },
          'isTakeaway': widget.isTakeaway,
          'timestamp': FieldValue.serverTimestamp(),
        });

        debugPrint('Transaction logged with ID: ${transactionRef.id}');
        success = true;
      });

      if (success) {
        // Verify Firestore update
        final updatedSnapshot = await balanceRef.get();
        if (!updatedSnapshot.exists ||
            updatedSnapshot.data()?['balance'] == null) {
          debugPrint('Error: Balance document invalid after update');
          return false;
        }
        final updatedBalance =
            (updatedSnapshot.data()!['balance'] as num).toDouble();
        debugPrint('Verified Firestore balance: $updatedBalance RITZ');

        // Clear carts only after Firestore confirmation
        widget.foodCart.clear();
        widget.stationeryCart.clear();
        debugPrint('Cleared carts after Firestore update');
        debugPrint('Food cart after payment: ${widget.foodCart}');
        debugPrint('Stationery cart after payment: ${widget.stationeryCart}');

        // Log purchase with PIN
        if (widget.foodCart.isNotEmpty) {
          final purchaseRef =
              FirebaseFirestore.instance.collection('purchases').doc();
          await purchaseRef.set({
            'userId': user.uid,
            'foodItems': widget.foodCart,
            'total': total,
            'isTakeaway': widget.isTakeaway,
            'timestamp': FieldValue.serverTimestamp(),
            'pin': (100 + (DateTime.now().millisecondsSinceEpoch % 900))
                .toString(),
          });
          debugPrint('Purchase logged with PIN to purchases collection');
        }

        return true;
      } else {
        debugPrint('Transaction failed: Insufficient balance or error');
        return false;
      }
    } catch (e) {
      debugPrint('Firestore error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to deduct balance: $e')),
        );
      }
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
                  StreamBuilder<DocumentSnapshot>(
                    stream: user != null
                        ? FirebaseFirestore.instance
                            .collection('user_balances')
                            .doc(user.uid)
                            .snapshots()
                        : null,
                    builder: (context, snapshot) {
                      double balance = 0.0;
                      if (snapshot.hasError) {
                        debugPrint('Stream error: ${snapshot.error}');
                      }
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final data =
                            snapshot.data!.data() as Map<String, dynamic>?;
                        if (data != null && data['balance'] != null) {
                          balance = (data['balance'] as num).toDouble();
                          debugPrint('UI balance updated: $balance RITZ');
                        } else {
                          debugPrint('Balance field missing in document');
                        }
                      } else {
                        debugPrint('Balance document not found or empty');
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
                  const SizedBox(height: 80),
                ],
              ),
            ),
            Positioned(
              bottom: 16.0,
              right: 16.0,
              child: GestureDetector(
                onTapDown: (_) => _buttonController.forward(),
                onTapUp: (_) => _buttonController.reverse(),
                onTapCancel: () => _buttonController.reverse(),
                onTap: () async {
                  debugPrint('Pay button clicked');
                  final success = await _processPayment();
                  if (success && mounted) {
                    debugPrint(
                        'Payment successful, navigating to success screen');
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const PaymentSuccessScreen()),
                    );
                  } else if (mounted) {
                    debugPrint('Payment failed, showing snackbar');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                            'Failed to deduct balance or insufficient funds'),
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
