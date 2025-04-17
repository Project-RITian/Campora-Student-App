import 'package:flutter/material.dart';
import '../models/food_item.dart';
import '../widgets/custom_navigation_drawer.dart';
import 'payment_screen.dart';

class CanteenScreen extends StatefulWidget {
  const CanteenScreen({super.key});

  @override
  _CanteenScreenState createState() => _CanteenScreenState();
}

class _CanteenScreenState extends State<CanteenScreen> {
  String _searchQuery = '';
  final Map<int, int> _foodCart = {};
  final List<FoodItem> _foodItems = [
    FoodItem(
      id: 1,
      name: "Hakka Noodles",
      price: 80, // Price in RITZ
      category: "Chinese",
      stock: 50,
      imageUrl: "https://via.placeholder.com/100x100.png?text=Noodles",
    ),
    FoodItem(
      id: 2,
      name: "Manchurian",
      price: 90, // Price in RITZ
      category: "Chinese",
      stock: 40,
      imageUrl: "https://via.placeholder.com/100x100.png?text=Manchurian",
    ),
    FoodItem(
      id: 3,
      name: "Mango Lassi",
      price: 40, // Price in RITZ
      category: "Beverages",
      stock: 60,
      imageUrl: "https://via.placeholder.com/100x100.png?text=Lassi",
    ),
    FoodItem(
      id: 4,
      name: "Cold Coffee",
      price: 50, // Price in RITZ
      category: "Beverages",
      stock: 70,
      imageUrl: "https://via.placeholder.com/100x100.png?text=Coffee",
    ),
    FoodItem(
      id: 5,
      name: "Vada Pav",
      price: 20, // Price in RITZ
      category: "Snacks",
      stock: 100,
      imageUrl: "https://via.placeholder.com/100x100.png?text=Vada+Pav",
    ),
    FoodItem(
      id: 6,
      name: "Samosa",
      price: 15, // Price in RITZ
      category: "Snacks",
      stock: 120,
      imageUrl: "https://via.placeholder.com/100x100.png?text=Samosa",
    ),
    FoodItem(
      id: 7,
      name: "Masala Dosa",
      price: 60, // Price in RITZ
      category: "South Indian",
      stock: 30,
      imageUrl: "https://via.placeholder.com/100x100.png?text=Dosa",
    ),
    FoodItem(
      id: 8,
      name: "Idli Sambhar",
      price: 50, // Price in RITZ
      category: "South Indian",
      stock: 40,
      imageUrl: "https://via.placeholder.com/100x100.png?text=Idli",
    ),
  ];

  void _addToCart(int itemId) {
    setState(() {
      _foodCart[itemId] = (_foodCart[itemId] ?? 0) + 1;
    });
  }

  void _removeFromCart(int itemId) {
    setState(() {
      if (_foodCart[itemId] != null && _foodCart[itemId]! > 0) {
        _foodCart[itemId] = _foodCart[itemId]! - 1;
        if (_foodCart[itemId] == 0) _foodCart.remove(itemId);
      }
    });
  }

  void _proceedToPayment() {
    if (_foodCart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add food items to cart')),
      );
      return;
    }
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
        ),
      ),
    );
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

    return Scaffold(
      appBar: AppBar(title: const Text('Canteen')),
      drawer: const CustomNavigationDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Search food items...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 20),
            ...categories.map((category) {
              final filteredItems = _getFilteredItems(category);
              if (filteredItems.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        final quantity = _foodCart[item.id] ?? 0;
                        return Container(
                          width: 150,
                          margin: const EdgeInsets.only(right: 10),
                          child: Card(
                            color: Colors.white,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(8.0)),
                                  child: Image.network(
                                    item.imageUrl,
                                    height: 80,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(Icons.error, size: 50),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${item.price} RITZ',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      Text(
                                        'Stock: ${item.stock}',
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove,
                                                size: 16),
                                            onPressed: () =>
                                                _removeFromCart(item.id),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(
                                              minWidth: 24,
                                              minHeight: 24,
                                            ),
                                          ),
                                          Text(
                                            quantity.toString(),
                                            style:
                                                const TextStyle(fontSize: 14),
                                          ),
                                          IconButton(
                                            icon:
                                                const Icon(Icons.add, size: 16),
                                            onPressed: () =>
                                                _addToCart(item.id),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(
                                              minWidth: 24,
                                              minHeight: 24,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              );
            }).toList(),
            ElevatedButton(
              onPressed: _proceedToPayment,
              child: const Text('Proceed to Payment'),
            ),
          ],
        ),
      ),
    );
  }
}
