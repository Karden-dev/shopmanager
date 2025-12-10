// lib/models/stock_item.dart

class StockItem {
  final int id;
  final String productName;
  final String? variantName; // Peut être null si pas de variante (ex: Taille Unique)
  final int quantity;
  final double price;
  final String? imageUrl;
  final String? reference; // SKU ou Ref interne

  const StockItem({
    required this.id,
    required this.productName,
    this.variantName,
    required this.quantity,
    required this.price,
    this.imageUrl,
    this.reference,
  });

  /// Factory pour créer un StockItem depuis le JSON de l'API
  factory StockItem.fromJson(Map<String, dynamic> json) {
    return StockItem(
      id: _parseInt(json['id']),
      
      // Gestion des différents noms de clés possibles venant du backend
      productName: json['name'] ?? json['product_name'] ?? 'Produit Inconnu',
      
      variantName: json['variant_name'] ?? json['variant'],
      
      // Sécurisation des nombres (parfois reçus en String "10" au lieu de int 10)
      quantity: _parseInt(json['quantity'] ?? json['stock_quantity']),
      price: _parseDouble(json['price']),
      
      imageUrl: json['image_url'] ?? json['image'],
      reference: json['reference'] ?? json['sku'],
    );
  }

  /// Méthode utilitaire pour convertir en Map (si besoin d'envoyer l'objet complet)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_name': productName,
      'variant_name': variantName,
      'quantity': quantity,
      'price': price,
      'image_url': imageUrl,
      'reference': reference,
    };
  }

  // --- HELPERS DE PARSING SÉCURISÉ ---
  // Ces fonctions évitent les crashs "type 'String' is not a subtype of type 'int'"

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '.')) ?? 0.0; // Gère "10,50" et "10.50"
  }
}