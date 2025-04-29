import 'package:cloud_firestore/cloud_firestore.dart';

class FoodItem {
  final String id;
  final String name;
  final double price;
  final String category;
  final int stock;
  final String imageUrl;
  final bool isInStock; // Added isInStock field

  FoodItem({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.stock,
    required this.imageUrl,
    required this.isInStock,
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
      'isInStock': isInStock, // Include isInStock in map
    };
  }

  // Factory method to create from Firestore document
  factory FoodItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FoodItem(
      id: doc.id,
      name: data['name']?.toString() ?? 'No Name',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      category: data['category']?.toString() ?? 'Uncategorized',
      stock: (data['stock'] as num?)?.toInt() ?? 100,
      imageUrl: data['imageUrl']?.toString() ?? '',
      isInStock:
          data['isInStock'] as bool? ?? true, // Default to true if missing
    );
  }
}
