import 'package:cloud_firestore/cloud_firestore.dart';

class FoodItem {
  final String id; // Changed from int to String
  final String name;
  final double price;
  final String category;
  final int stock;
  final String imageUrl;

  FoodItem({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.stock,
    required this.imageUrl,
  });

  // Helper method to convert to map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'category': category,
      'stock': stock,
      'imageUrl': imageUrl,
    };
  }

  // Factory method to create from Firestore document
  factory FoodItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FoodItem(
      id: doc.id, // Using document ID as the item ID
      name: data['name'] ?? 'No Name',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      category: data['category'] ?? 'Uncategorized',
      stock: data['stock'] ?? 100, // Use actual stock if available
      imageUrl: data['imageUrl'] ?? '',
    );
  }
}
