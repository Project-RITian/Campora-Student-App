class FoodItem {
  final int id;
  final String name;
  final double price; // Price in RITZ
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
}
