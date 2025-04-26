import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../widgets/custom_navigation_drawer.dart';

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
  double? userBalance;
  bool isLoading = true;

  final List<Map<String, dynamic>> _ritzPackages = [
    {'ritz': 100, 'price': 100}, // ₹100 for 100 RITZ
    {'ritz': 500, 'price': 450}, // ₹450 for 500 RITZ
    {'ritz': 1000, 'price': 850}, // ₹850 for 1000 RITZ
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserBalance();
  }

  Future<void> _fetchUserBalance() async {
    final user = fb_auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        isLoading = false;
        userBalance = 0.0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to view balance')),
      );
      return;
    }

    try {
      final docRef =
          FirebaseFirestore.instance.collection('user_balances').doc(user.uid);
      final doc = await docRef.get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (!data.containsKey('balance') || data['balance'] == null) {
          await docRef.set({'balance': 100.0}, SetOptions(merge: true));
          setState(() {
            userBalance = 100.0;
            isLoading = false;
          });
          return;
        }

        dynamic balanceData = data['balance'];
        double balanceValue;
        if (balanceData is num) {
          balanceValue = balanceData.toDouble();
        } else if (balanceData is String) {
          balanceValue = double.tryParse(balanceData) ?? 0.0;
        } else {
          balanceValue = 0.0;
        }
        setState(() {
          userBalance = balanceValue;
          isLoading = false;
        });
      } else {
        await docRef.set({'balance': 100.0}, SetOptions(merge: true));
        setState(() {
          userBalance = 100.0;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching balance: $e');
      setState(() {
        isLoading = false;
        userBalance = 0.0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching balance: $e')),
      );
    }
  }

  Future<void> _purchaseRitz(double ritzAmount) async {
    // Validate inputs
    if (_paymentMethod == 'card') {
      if (_cardNumberController.text.length != 16 ||
          _expiryDateController.text.isEmpty ||
          _cvvController.text.length != 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid card details')),
        );
        return;
      }
    } else if (_paymentMethod == 'upi') {
      if (_upiIdController.text.isEmpty ||
          !_upiIdController.text.contains('@')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid UPI ID')),
        );
        return;
      }
    }

    try {
      final user = fb_auth.FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to purchase RITZ')),
        );
        return;
      }

      // Update Firestore balance
      final balanceRef =
          FirebaseFirestore.instance.collection('user_balances').doc(user.uid);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(balanceRef);
        double currentBalance = 0.0;
        if (snapshot.exists) {
          currentBalance =
              (snapshot.data()?['balance'] as num?)?.toDouble() ?? 0.0;
        }
        final newBalance = currentBalance + ritzAmount;
        transaction.set(
            balanceRef, {'balance': newBalance}, SetOptions(merge: true));
      });

      // Update local balance
      setState(() {
        userBalance = (userBalance ?? 0.0) + ritzAmount;
      });

      // Clear payment details after success
      _cardNumberController.clear();
      _expiryDateController.clear();
      _cvvController.clear();
      _upiIdController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully purchased $ritzAmount RITZ')),
      );
      Navigator.pop(context);
    } catch (e) {
      print('Error purchasing RITZ: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to purchase RITZ')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buy RITZ'),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
      ),
      drawer: const CustomNavigationDrawer(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromARGB(255, 255, 255, 255),
                    Color.fromARGB(255, 237, 247, 255)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Logo
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
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
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
                    const SizedBox(height: 10),
                    Text(
                      'Balance: ${userBalance?.toStringAsFixed(2) ?? "0.00"} RITZ',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
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
                                    const FaIcon(
                                      FontAwesomeIcons.coins,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                            color:
                                                Colors.white.withOpacity(0.9),
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
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        children: [
                          RadioListTile<String>(
                            title: const Text('Credit/Debit Card',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                            value: 'card',
                            groupValue: _paymentMethod,
                            onChanged: (value) =>
                                setState(() => _paymentMethod = value!),
                            activeColor: Colors.amber[700],
                            secondary: FaIcon(FontAwesomeIcons.creditCard,
                                color: Colors.amber[700]),
                          ),
                          RadioListTile<String>(
                            title: const Text('UPI',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                            value: 'upi',
                            groupValue: _paymentMethod,
                            onChanged: (value) =>
                                setState(() => _paymentMethod = value!),
                            activeColor: Colors.amber[700],
                            secondary: FaIcon(FontAwesomeIcons.wallet,
                                color: Colors.amber[700]),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
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
                                decoration: _inputDecoration(
                                    'Card Number (16 digits)',
                                    FontAwesomeIcons.creditCard),
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _expiryDateController,
                                decoration: _inputDecoration(
                                    'Expiry Date (MM/YY)',
                                    FontAwesomeIcons.calendar),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _cvvController,
                                decoration: _inputDecoration(
                                    'CVV (3 digits)', FontAwesomeIcons.lock),
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
                            decoration: _inputDecoration(
                                'UPI ID', FontAwesomeIcons.wallet),
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

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      prefixIcon: FaIcon(icon, color: Colors.amber[700]),
    );
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    _upiIdController.dispose();
    super.dispose();
  }
}
