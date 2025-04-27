import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import '../models/food_item.dart';
import '../widgets/custom_navigation_drawer.dart';
import 'payment_screen.dart';

class CanteenScreen extends StatefulWidget {
  const CanteenScreen({super.key});

  @override
  _CanteenScreenState createState() => _CanteenScreenState();
}

class _CanteenScreenState extends State<CanteenScreen>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  final Map<String, int> _foodCart = {};

  void _addToCart(String itemId) {
    final item = _foodItems.firstWhere((food) => food.id == itemId);
    if (item.stock <= (_foodCart[itemId] ?? 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.name} is out of stock')),
      );
      return;
    }
    setState(() => _foodCart[itemId] = (_foodCart[itemId] ?? 0) + 1);
  }

  void _removeFromCart(String itemId) {
    setState(() {
      if (_foodCart[itemId] != null && _foodCart[itemId]! > 0) {
        _foodCart[itemId] = _foodCart[itemId]! - 1;
        if (_foodCart[itemId] == 0) _foodCart.remove(itemId);
      }
    });
  }

  late AnimationController _buttonController;
  late Animation<double> _buttonScaleAnimation;
  bool _isTakeaway = false;
  double? userBalance;
  bool isLoading = true;
  bool _isProcessingPayment = false;
  bool _isLoggingPurchase = false;
  List<FoodItem> _foodItems = [];
  bool _isLoadingFoodItems = true;

  final List<String> _categories = [
    'Chinese',
    'Beverages',
    'Snacks',
    'South Indian',
  ];

  @override
  void initState() {
    super.initState();
    _buttonController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
        CurvedAnimation(parent: _buttonController, curve: Curves.bounceOut));
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );
    _fetchUserBalance();
    _fetchFoodItems();
  }

  @override
  void dispose() {
    _buttonController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserBalance() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          userBalance = 0.0;
          isLoading = false;
        });
        return;
      }
      final doc = await FirebaseFirestore.instance
          .collection('user_balances')
          .doc(user.uid)
          .get();
      setState(() {
        userBalance = (doc.data()?['balance'] as num?)?.toDouble() ?? 0.0;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching user balance: $e');
      setState(() {
        userBalance = 0.0;
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading balance: $e')),
      );
    }
  }

  Future<void> _fetchFoodItems() async {
    try {
      print('Fetching food items from Firestore...');
      final querySnapshot = await FirebaseFirestore.instance
          .collection('foods')
          .orderBy('createdAt', descending: true)
          .get();

      final items =
          querySnapshot.docs.map((doc) => FoodItem.fromFirestore(doc)).toList();

      setState(() {
        _foodItems = items;
        _isLoadingFoodItems = false;
      });
      print('Successfully loaded ${items.length} food items');
    } catch (e) {
      print('Error fetching food items: $e');
      setState(() {
        _isLoadingFoodItems = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading food items: $e')),
      );
    }
  }

  List<FoodItem> _getFilteredItems(String category) {
    return _foodItems.where((item) {
      final matchesCategory = item.category == category;
      final matchesSearch =
          item.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch && item.stock > 0;
    }).toList();
  }

  double _calculateTotalCost() {
    double total = 0.0;
    _foodCart.forEach((itemId, qty) {
      final item = _foodItems.firstWhere((food) => food.id == itemId);
      total += item.price * qty;
    });
    if (_isTakeaway) total += 3.0;
    return total;
  }

  Future<void> _logPurchase() async {
    if (_foodCart.isEmpty) return;
    setState(() => _isLoggingPurchase = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to log purchase')),
        );
        return;
      }
      final batch = FirebaseFirestore.instance.batch();
      for (var entry in _foodCart.entries) {
        final item = _foodItems.firstWhere((food) => food.id == entry.key);
        final purchaseRef = FirebaseFirestore.instance
            .collection('purchases')
            .doc(); // New document for each purchase
        batch.set(purchaseRef, {
          'userId': user.uid,
          'itemId': item.id,
          'itemName': item.name,
          'quantity': entry.value,
          'totalCost': item.price * entry.value,
          'isTakeaway': _isTakeaway,
          'timestamp': FieldValue.serverTimestamp(),
        });
        // Update stock
        final foodRef =
            FirebaseFirestore.instance.collection('foods').doc(item.id);
        batch.update(foodRef, {'stock': item.stock - entry.value});
      }
      await batch.commit();
      print('Purchase logged successfully');
    } catch (e) {
      print('Error logging purchase: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging purchase: $e')),
      );
    } finally {
      setState(() => _isLoggingPurchase = false);
    }
  }

  void _proceedToPayment() async {
    if (_foodCart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty')),
      );
      return;
    }
    setState(() => _isProcessingPayment = true);
    try {
      await _logPurchase();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentScreen(
            file: null,
            copies: 0,
            isColor: false,
            printSide: '',
            customInstructions: '',
            stationeryCart: {}, // Empty stationery cart
            stationeryItems: [], // Empty stationery items
            foodCart: Map.from(_foodCart),
            foodItems: _foodItems,
            isTakeaway: _isTakeaway,
          ),
        ),
      );
      // Clear cart after navigating
      setState(() {
        _foodCart.clear();
        _isTakeaway = false;
      });
    } catch (e) {
      print('Error proceeding to payment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error proceeding to payment: $e')),
      );
    } finally {
      setState(() => _isProcessingPayment = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalItems = _foodCart.values.fold(0, (sum, count) => sum + count);

    return Scaffold(
      appBar: CustomNavigationDrawer.buildAppBar(context, 'Canteen'),
      drawer: const CustomNavigationDrawer(),
      body: isLoading || _isLoadingFoodItems
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0C4D83), Color(0xFF64B5F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Canteen Menu',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Balance: ${userBalance?.toStringAsFixed(2) ?? "0.00"} RITZ',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Total: ${_calculateTotalCost().toStringAsFixed(2)} RITZ',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search for food or drinks...',
                          hintStyle: const TextStyle(color: Colors.grey),
                          prefixIcon:
                              const Icon(Icons.search, color: Colors.white),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.2),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 12.0, horizontal: 20.0),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30.0),
                              borderSide: BorderSide.none),
                        ),
                        style: const TextStyle(color: Colors.white),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    _foodItems.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Text(
                                'No food items available',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _categories.length,
                            itemBuilder: (context, catIndex) {
                              final category = _categories[catIndex];
                              final filteredItems = _getFilteredItems(category);
                              if (filteredItems.isEmpty)
                                return const SizedBox.shrink();
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    category,
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                  const SizedBox(height: 8),
                                  ...filteredItems.map((item) {
                                    final quantity = _foodCart[item.id] ?? 0;
                                    return AnimatedOpacity(
                                      opacity: 1.0,
                                      duration:
                                          const Duration(milliseconds: 500),
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.95),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.1),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: ListTile(
                                          contentPadding:
                                              const EdgeInsets.all(12),
                                          leading: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: Image.network(
                                              item.imageUrl,
                                              width: 70,
                                              height: 70,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error,
                                                      stackTrace) =>
                                                  const Icon(Icons.fastfood),
                                            ),
                                          ),
                                          title: Text(
                                            item.name,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87),
                                          ),
                                          subtitle: Text(
                                            '${item.price} RITZ',
                                            style: TextStyle(
                                                color: Colors.teal[300]),
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              GestureDetector(
                                                onTap: () =>
                                                    _removeFromCart(item.id),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(6.0),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[200],
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.remove,
                                                    size: 16,
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8.0),
                                                child: Text(
                                                  quantity.toString(),
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF0C4D83),
                                                  ),
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () =>
                                                    _addToCart(item.id),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(6.0),
                                                  decoration:
                                                      const BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        Color(0xFF0C4D83),
                                                        Color(0xFF64B5F6)
                                                      ],
                                                      begin: Alignment.topLeft,
                                                      end:
                                                          Alignment.bottomRight,
                                                    ),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.add,
                                                    size: 16,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ],
                              );
                            },
                          ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text(
                        'Takeaway (+3 RITZ)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      value: _isTakeaway,
                      activeColor: Colors.teal,
                      onChanged: (value) {
                        setState(() {
                          _isTakeaway = value;
                        });
                      },
                    ),
                    const SizedBox(height: 70),
                  ],
                ),
              ),
            ),
      floatingActionButton: _isProcessingPayment || _isLoggingPurchase
          ? const CircularProgressIndicator()
          : GestureDetector(
              onTap: _proceedToPayment,
              child: AnimatedBuilder(
                animation: _buttonScaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _buttonScaleAnimation.value,
                    child: Container(
                      height: 60,
                      width: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0C4D83), Color(0xFF64B5F6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(
                              Icons.shopping_cart,
                              color: Colors.white,
                              size: 28,
                            ),
                            if (totalItems > 0)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    totalItems.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
