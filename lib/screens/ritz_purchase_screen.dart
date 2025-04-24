import 'package:flutter/material.dart';
import '../widgets/custom_navigation_drawer.dart';
import 'payment_screen.dart'; // For UserBalance
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
      appBar: AppBar(
        title: const Text('Buy RITZ'),
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
      ),
      drawer: const CustomNavigationDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 255, 255, 255), Color.fromARGB(255, 237, 247, 255)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // RITZ Coin Logo
              Container(
                margin: const EdgeInsets.only(top: 20, bottom: 20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'lib/assets/images/ritz_logo.png',
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 100,
                      height: 100,
                      color: Colors.grey[300],
                      child: const Icon(Icons.error, color: Colors.red),
                    ),
                  ),
                ),
              ),
              const Text(
                'Purchase RITZ',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              // RITZ Packages
              ..._ritzPackages.asMap().entries.map((entry) {
                final index = entry.key;
                final package = entry.value;
                return AnimatedOpacity(
                  opacity: 1.0,
                  duration: Duration(milliseconds: 300 + (index * 100)),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.amber[600]!, Colors.amber[800]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              FaIcon(
                                FontAwesomeIcons.coins,
                                color: Colors.white,
                                size: 30,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${package['ritz']} RITZ',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    '₹${package['price']}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          ElevatedButton(
                            onPressed: () =>
                                _purchaseRitz(package['ritz'].toDouble()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.amber[800],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              elevation: 2,
                            ),
                            child: const Text(
                              'Buy',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 30),
              const Text(
                'Payment Method',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              // Payment Method Selection
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text(
                        'Credit/Debit Card',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      value: 'card',
                      groupValue: _paymentMethod,
                      onChanged: (value) =>
                          setState(() => _paymentMethod = value!),
                      activeColor: Colors.amber[700],
                      secondary: FaIcon(
                        FontAwesomeIcons.creditCard,
                        color: Colors.amber[700],
                      ),
                    ),
                    RadioListTile<String>(
                      title: const Text(
                        'UPI',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      value: 'upi',
                      groupValue: _paymentMethod,
                      onChanged: (value) =>
                          setState(() => _paymentMethod = value!),
                      activeColor: Colors.amber[700],
                      secondary: FaIcon(
                        FontAwesomeIcons.wallet,
                        color: Colors.amber[700],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Payment Details Input
              if (_paymentMethod == 'card')
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextField(
                          controller: _cardNumberController,
                          decoration: InputDecoration(
                            labelText: 'Card Number (16 digits)',
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: FaIcon(
                              FontAwesomeIcons.creditCard,
                              color: Colors.amber[700],
                            ),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _expiryDateController,
                          decoration: InputDecoration(
                            labelText: 'Expiry Date (MM/YY)',
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: FaIcon(
                              FontAwesomeIcons.calendar,
                              color: Colors.amber[700],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _cvvController,
                          decoration: InputDecoration(
                            labelText: 'CVV (3 digits)',
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: FaIcon(
                              FontAwesomeIcons.lock,
                              color: Colors.amber[700],
                            ),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  ),
                ),
              if (_paymentMethod == 'upi')
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _upiIdController,
                      decoration: InputDecoration(
                        labelText: 'UPI ID',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: FaIcon(
                          FontAwesomeIcons.wallet,
                          color: Colors.amber[700],
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
