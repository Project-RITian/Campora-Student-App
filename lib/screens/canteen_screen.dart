import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
  final Map<int, int> _foodCart = {};
  late AnimationController _buttonController;
  late Animation<double> _buttonScaleAnimation;
  bool _isTakeaway = false;
  double? userBalance;
  bool isLoading = true;

  final List<FoodItem> _foodItems = [
    FoodItem(
        id: 1,
        name: "Hakka Noodles",
        price: 80,
        category: "Chinese",
        stock: 50,
        imageUrl:
            "https://www.indianhealthyrecipes.com/wp-content/uploads/2021/07/hakka-noodles-recipe.jpg"),
    FoodItem(
        id: 2,
        name: "Manchurian",
        price: 90,
        category: "Chinese",
        stock: 40,
        imageUrl: "https://source.unsplash.com/featured/?manchurian"),
    FoodItem(
        id: 3,
        name: "Mango Lassi",
        price: 40,
        category: "Beverages",
        stock: 60,
        imageUrl: "https://source.unsplash.com/featured/?mango-lassi"),
    FoodItem(
        id: 4,
        name: "Cold Coffee",
        price: 50,
        category: "Beverages",
        stock: 70,
        imageUrl: "https://source.unsplash.com/featured/?cold-coffee"),
    FoodItem(
        id: 5,
        name: "Vada Pav",
        price: 20,
        category: "Snacks",
        stock: 100,
        imageUrl: "https://source.unsplash.com/featured/?vada-pav"),
    FoodItem(
        id: 6,
        name: "Samosa",
        price: 15,
        category: "Snacks",
        stock: 120,
        imageUrl: "https://source.unsplash.com/featured/?samosa"),
    FoodItem(
        id: 7,
        name: "Masala Dosa",
        price: 60,
        category: "South Indian",
        stock: 30,
        imageUrl: "https://source.unsplash.com/featured/?masala-dosa"),
    FoodItem(
        id: 8,
        name: "Idli Sambhar",
        price: 50,
        category: "South Indian",
        stock: 40,
        imageUrl: "https://source.unsplash.com/featured/?idli-sambhar"),
    FoodItem(
        id: 9,
        name: "Puri",
        price: 50,
        category: "South Indian",
        stock: 40,
        imageUrl: "https://source.unsplash.com/featured/?puri"),
  ];

  @override
  void initState() {
    super.initState();
    _buttonController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
        CurvedAnimation(parent: _buttonController, curve: Curves.bounceOut));
    _fetchUserBalance();
  }

  @override
  void dispose() {
    _buttonController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserBalance() async {
    final user = FirebaseAuth.instance.currentUser;
    print(
        'Current user: ${user?.uid ?? "No user signed in"}'); // Debug: Log user ID
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
      print(
          'Fetching balance from Firestore: user_balances/${user.uid}/balance'); // Debug: Log path
      final doc = await docRef.get();
      print(
          'Firestore document exists: ${doc.exists}'); // Debug: Check document existence
      print(
          'Firestore document data: ${doc.data()}'); // Debug: Log document data

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (!data.containsKey('balance') || data['balance'] == null) {
          print(
              'Balance field missing or null in user_balances/${user.uid}, setting to 100.0'); // Debug: Log missing balance
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
          print(
              'Balance is string: "$balanceData", parsed to: $balanceValue'); // Debug: Log string parsing
        } else {
          print(
              'Invalid balance type: ${balanceData.runtimeType}, setting to 0.0'); // Debug: Log invalid type
          balanceValue = 0.0;
        }
        print('Parsed balance: $balanceValue'); // Debug: Log parsed balance
        setState(() {
          userBalance = balanceValue;
          isLoading = false;
        });
      } else {
        print(
            'No document found for user ${user.uid}, creating new document with balance 100.0'); // Debug: Log document creation
        await docRef.set({'balance': 100.0});
        setState(() {
          userBalance = 100.0;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching balance: $e'); // Debug: Log error
      setState(() {
        isLoading = false;
        userBalance = 0.0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching balance: $e')),
      );
    }
  }

  // Temporary method to reset balance to 965.0 for debugging
  Future<void> _resetBalance() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to reset balance')),
      );
      return;
    }

    try {
      final docRef =
          FirebaseFirestore.instance.collection('user_balances').doc(user.uid);
      print(
          'Resetting balance to 965.0 for user ${user.uid}'); // Debug: Log reset attempt
      await docRef.set({'balance': 965.0}, SetOptions(merge: true));
      print(
          'Balance reset to 965.0, refreshing balance'); // Debug: Log reset success
      await _fetchUserBalance();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Balance reset to 965.0 RITZ')),
      );
    } catch (e) {
      print('Error resetting balance: $e'); // Debug: Log error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error resetting balance: $e')),
      );
    }
  }

  void _addToCart(int itemId) {
    setState(() => _foodCart[itemId] = (_foodCart[itemId] ?? 0) + 1);
  }

  void _removeFromCart(int itemId) {
    setState(() {
      if (_foodCart[itemId] != null && _foodCart[itemId]! > 0) {
        _foodCart[itemId] = _foodCart[itemId]! - 1;
        if (_foodCart[itemId] == 0) _foodCart.remove(itemId);
      }
    });
  }

  double _calculateTotalCost() {
    double total = 0.0;
    _foodCart.forEach((id, quantity) {
      final item = _foodItems.firstWhere((item) => item.id == id);
      total += item.price * quantity;
    });
    if (_isTakeaway) {
      total += 3;
    }
    return total;
  }

  Future<void> _proceedToPayment() async {
    if (_foodCart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add food items to cart')),
      );
      return;
    }

    final totalCost = _calculateTotalCost();
    print(
        'Total cost: $totalCost, User balance: $userBalance'); // Debug: Log cost and balance
    if (totalCost <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No items to purchase')),
      );
      return;
    }

    // Refresh balance if it's 0 or null to ensure accuracy
    if (userBalance == null || userBalance == 0.0) {
      print(
          'Balance is 0 or null, attempting to refresh'); // Debug: Log refresh attempt
      await _fetchUserBalance();
      if (userBalance == null || userBalance == 0.0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to fetch balance, please try again')),
        );
        return;
      }
    }

    if (totalCost > userBalance!) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient balance')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to proceed')),
      );
      return;
    }

    // Navigate to PaymentScreen without deducting balance
    _buttonController.forward().then((_) {
      _buttonController.reverse();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentScreen(
            file: null,
            copies: 0,
            isColor: false,
            printSide: '',
            customInstructions: '',
            stationeryCart: {},
            stationeryItems: [],
            foodCart: _foodCart,
            foodItems: _foodItems,
            isTakeaway: _isTakeaway,
          ),
        ),
      ).then((_) {
        // Refresh balance and clear cart after returning from PaymentScreen
        _fetchUserBalance();
        setState(() {
          _foodCart.clear();
        });
      });
    });
  }

  List<FoodItem> _getFilteredItems(String category) {
    return _foodItems
        .where((item) =>
            item.category == category &&
            item.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['Chinese', 'Beverages', 'Snacks', 'South Indian'];
    final totalItems = _foodCart.values.fold(0, (sum, count) => sum + count);

    return Scaffold(
      appBar: CustomNavigationDrawer.buildAppBar(context, 'Canteen'),
      drawer: const CustomNavigationDrawer(),
      body: isLoading
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
                    // Balance Display
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
                    // Total Cost Display
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
                    // Search Bar
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
                    // Food Items
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: categories.length,
                      itemBuilder: (context, catIndex) {
                        final category = categories[catIndex];
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
                                duration: const Duration(milliseconds: 500),
                                child: Container(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.95),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(12),
                                    leading: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        item.imageUrl,
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(Icons.error),
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
                                      style: TextStyle(color: Colors.teal[300]),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        GestureDetector(
                                          onTap: () => _removeFromCart(item.id),
                                          child: Container(
                                            padding: const EdgeInsets.all(6.0),
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
                                          padding: const EdgeInsets.symmetric(
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
                                          onTap: () => _addToCart(item.id),
                                          child: Container(
                                            padding: const EdgeInsets.all(6.0),
                                            decoration: const BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Color(0xFF0C4D83),
                                                  Color(0xFF64B5F6)
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
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
                    // Takeaway Toggle
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
      floatingActionButton: GestureDetector(
        onTap: _proceedToPayment,
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
