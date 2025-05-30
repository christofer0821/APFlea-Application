class ListingModel {
  final String id;
  final String title;
  final String description;
  final double price;
  final int quantity;
  final String condition;
  final int quality;
  final String imageUrl;
  final String sellerId;
  final DateTime createdAt;
  final bool isSold;
  final String locationState;  // ✅ split field
  final String locationCity;   // ✅ split field

  ListingModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.quantity,
    required this.condition,
    required this.quality,
    required this.imageUrl,
    required this.sellerId,
    required this.createdAt,
    required this.locationState,
    required this.locationCity,
    this.isSold = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'quantity': quantity,
      'condition': condition,
      'quality': quality,
      'imageUrl': imageUrl,
      'sellerId': sellerId,
      'createdAt': createdAt.toIso8601String(),
      'locationState': locationState,
      'locationCity': locationCity,
      'isSold': isSold,
    };
  }

  factory ListingModel.fromMap(String id, Map<String, dynamic> map) {
    return ListingModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] as num).toDouble(),
      quantity: map['quantity'] ?? 1,
      condition: map['condition'] ?? 'Used',
      quality: map['quality'] ?? 5,
      imageUrl: map['imageUrl'] ?? '',
      sellerId: map['sellerId'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      locationState: map['locationState'] ?? '',
      locationCity: map['locationCity'] ?? '',
      isSold: map['isSold'] ?? false,
    );
  }
}
