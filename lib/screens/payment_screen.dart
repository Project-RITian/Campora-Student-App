import 'dart:io';
import 'package:flutter/material.dart';
import '../models/stationery_item.dart';
import '../models/food_item.dart';
import '../widgets/custom_navigation_drawer.dart';
import 'payment_success_screen.dart';
import 'ritz_purchase_screen.dart';

// Simple user balance management (replace with backend or state management)
class UserBalance {
  static double _ritzBalance = 1000; // Initial balance for testing

  static double get balance => _ritzBalance;

  static void addRitz(double amount) {
    _ritzBalance += amount;
  }

  static bool deductRitz(double amount) {
    if (_ritzBalance >= amount) {
      _ritzBalance -= amount;
      return true;
    }
    return false;
  }
}

class PaymentScreen extends StatefulWidget {
  final File? file;
  final int copies;
  final bool isColor;
  final String printSide;
  final String customInstructions;
  final Map<int, int> stationeryCart;
  final List<StationeryItem> stationeryItems;
  final Map<int, int> foodCart;
  final List<FoodItem> foodItems;

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
  });

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
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
    return total;
  }

  void _processPayment() {
    final total = _calculateTotal();
    if (UserBalance.deductRitz(total)) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PaymentSuccessScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Insufficient RITZ balance'),
          action: SnackBarAction(
            label: 'Buy RITZ',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const RitzPurchaseScreen()),
              );
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _calculateTotal();
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      drawer: const CustomNavigationDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display xerox details
            if (widget.file != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      'Xerox: ${widget.copies} copies (${widget.isColor ? 'Color' : 'B/W'})'),
                  Text('Print Side: ${widget.printSide}'),
                  if (widget.customInstructions.isNotEmpty)
                    Text('Instructions: ${widget.customInstructions}'),
                ],
              ),
            // Display stationery items
            if (widget.stationeryCart.isNotEmpty)
              ...widget.stationeryCart.entries.map((entry) {
                final item =
                    widget.stationeryItems.firstWhere((i) => i.id == entry.key);
                return Text(
                    '${item.name}: ${entry.value} x ${item.price} RITZ = ${item.price * entry.value} RITZ');
              }),
            // Display food items
            if (widget.foodCart.isNotEmpty)
              ...widget.foodCart.entries.map((entry) {
                final item =
                    widget.foodItems.firstWhere((i) => i.id == entry.key);
                return Text(
                    '${item.name}: ${entry.value} x ${item.price} RITZ = ${item.price * entry.value} RITZ');
              }),
            const SizedBox(height: 10),
            Text('Total: $total RITZ',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('Available Balance: ${UserBalance.balance} RITZ',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _processPayment,
              child: const Text('Pay with RITZ'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const RitzPurchaseScreen()),
                );
              },
              child: const Text('Buy More RITZ'),
            ),
          ],
        ),
      ),
    );
  }
}