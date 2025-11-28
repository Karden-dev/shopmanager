// lib/models/product.dart

class Product {
  final int id;
  final String reference;
  final String name;
  final String? variant;
  final int quantity;
  final int alertThreshold;
  final double sellingPrice;
  final String? imageUrl;

  Product({
    required this.id,
    required this.reference,
    required this.name,
    this.variant,
    required this.quantity,
    required this.alertThreshold,
    required this.sellingPrice,
    this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      reference: json['reference'] ?? '',
      name: json['name'] ?? 'Inconnu',
      variant: json['variant'],
      // Gérer le cas où la donnée vient de SQLite (int) ou API (parfois string)
      quantity: int.tryParse(json['quantity'].toString()) ?? 0,
      alertThreshold: int.tryParse(json['alert_threshold'].toString()) ?? 5,
      sellingPrice: double.tryParse(json['selling_price'].toString()) ?? 0.0,
      imageUrl: json['image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reference': reference,
      'name': name,
      'variant': variant,
      'quantity': quantity,
      'alert_threshold': alertThreshold,
      'selling_price': sellingPrice,
      'image_url': imageUrl,
    };
  }
}