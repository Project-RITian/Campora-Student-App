class StationeryItem {
  final int id;
  final String name;
  final double price; // Price in RITZ
  final int stock;
  final String imageUrl;

  StationeryItem({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.imageUrl,
  });

  factory StationeryItem.fromJson(Map<String, dynamic> json) {
    return StationeryItem(
      id: json['id'],
      name: json['name'],
      price: json['price'].toDouble(),
      stock: json['stock'],
      imageUrl: json['imageUrl'],
    );
  }
}
