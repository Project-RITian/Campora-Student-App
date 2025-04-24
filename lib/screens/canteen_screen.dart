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
  bool _isTakeaway = false; // New state for takeaway option

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
  }

  @override
  void dispose() {
    _buttonController.dispose();
    super.dispose();
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

  void _proceedToPayment() {
    if (_foodCart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add food items to cart')));
      return;
    }
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
      );
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search for food or drinks...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 12.0, horizontal: 20.0),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide.none),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: categories.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, catIndex) {
                final category = categories[catIndex];
                final filteredItems = _getFilteredItems(category);
                if (filteredItems.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0C4D83))),
                    const SizedBox(height: 8),
                    ...filteredItems.map((item) {
                      final quantity = _foodCart[item.id] ?? 0;
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 3,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(item.imageUrl,
                                width: 70, height: 70, fit: BoxFit.cover),
                          ),
                          title: Text(item.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('${item.price} RITZ',
                              style: const TextStyle(color: Colors.teal)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () => _removeFromCart(item.id)),
                              Text(quantity.toString(),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () => _addToCart(item.id)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _proceedToPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0C4D83),
                padding: const EdgeInsets.symmetric(
                    vertical: 12.0, horizontal: 24.0),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shopping_cart, color: Colors.white),
                  const SizedBox(width: 6),
                  Text('Cart ($totalItems)',
                      style:
                          const TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
            ),
          ),
          SwitchListTile(
            title: const Text(
              'Takeaway (+3 RITZ)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0C4D83),
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
        ],
      ),
    );
  }
}
