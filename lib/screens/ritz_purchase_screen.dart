import 'package:flutter/material.dart';
import '../widgets/custom_navigation_drawer.dart';
import 'payment_screen.dart'; // For UserBalance

class RitzPurchaseScreen extends StatefulWidget {
  const RitzPurchaseScreen({super.key});

  @override
  _RitzPurchaseScreenState createState() => _RitzPurchaseScreenState();
}

class _RitzPurchaseScreenState extends State<RitzPurchaseScreen> {
  String _paymentMethod = 'card';
  final _cardNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();
  final _upiIdController = TextEditingController();

  final List<Map<String, dynamic>> _ritzPackages = [
    {'ritz': 100, 'price': 100}, // ₹100 for 100 RITZ
    {'ritz': 500, 'price': 450}, // ₹450 for 500 RITZ (discount)
    {'ritz': 1000, 'price': 850}, // ₹850 for 1000 RITZ (discount)
  ];

  void _purchaseRitz(double ritzAmount) {
    if (_paymentMethod == 'card' &&
        (_cardNumberController.text.length != 16 ||
            _expiryDateController.text.isEmpty ||
            _cvvController.text.length != 3)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid card details')),
      );
      return;
    }
    if (_paymentMethod == 'upi' && _upiIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid UPI ID')),
      );
      return;
    }
    UserBalance.addRitz(ritzAmount);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Successfully purchased $ritzAmount RITZ')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buy RITZ')),
      drawer: const CustomNavigationDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Purchase RITZ',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ..._ritzPackages.map((package) {
              return Card(
                child: ListTile(
                  title: Text('${package['ritz']} RITZ'),
                  subtitle: Text('₹${package['price']}'),
                  trailing: ElevatedButton(
                    onPressed: () => _purchaseRitz(package['ritz'].toDouble()),
                    child: const Text('Buy'),
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),
            const Text(
              'Payment Method',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            RadioListTile<String>(
              title: const Text('Credit/Debit Card'),
              value: 'card',
              groupValue: _paymentMethod,
              onChanged: (value) => setState(() => _paymentMethod = value!),
            ),
            RadioListTile<String>(
              title: const Text('UPI'),
              value: 'upi',
              groupValue: _paymentMethod,
              onChanged: (value) => setState(() => _paymentMethod = value!),
            ),
            if (_paymentMethod == 'card')
              Column(
                children: [
                  TextField(
                    controller: _cardNumberController,
                    decoration: const InputDecoration(
                        labelText: 'Card Number (16 digits)'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: _expiryDateController,
                    decoration:
                        const InputDecoration(labelText: 'Expiry Date (MM/YY)'),
                  ),
                  TextField(
                    controller: _cvvController,
                    decoration:
                        const InputDecoration(labelText: 'CVV (3 digits)'),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            if (_paymentMethod == 'upi')
              TextField(
                controller: _upiIdController,
                decoration: const InputDecoration(labelText: 'UPI ID'),
              ),
          ],
        ),
      ),
    );
  }
}
