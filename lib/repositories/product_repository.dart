// lib/repositories/product_repository.dart

import 'package:flutter/foundation.dart';
import 'package:wink_merchant/services/api_service.dart';
import 'package:wink_merchant/services/database_service.dart';
import 'package:wink_merchant/models/product.dart';

class ProductRepository {
  final ApiService _apiService;
  final DatabaseService _dbService = DatabaseService();

  ProductRepository(this._apiService);

  /// 1. Récupère les produits (API + Cache Local)
  /// URL Serveur: GET /api/products/shop/:shopId
  Future<List<Product>> getProducts(int shopId) async {
    try {
      // Appel API
      final response = await _apiService.client.get('/products/shop/$shopId');
      final List<dynamic> serverData = response.data;
      
      // Sauvegarde locale (Cache) pour le mode offline
      await _dbService.batchInsertProducts(serverData);
      
      return serverData.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      debugPrint("Mode Offline ou Erreur API : ${e.toString()}");
      // En cas d'erreur, on charge depuis la base locale
      final localData = await _dbService.getAllProducts();
      return localData.map((json) => Product.fromJson(json)).toList();
    }
  }

  /// 2. Création d'un produit
  /// URL Serveur: POST /api/products
  Future<Product> createProduct(Map<String, dynamic> productData) async {
    try {
      final response = await _apiService.client.post('/products', data: productData);
      // On retourne l'objet créé (avec son nouvel ID)
      return Product.fromJson(response.data); 
    } catch (e) {
      rethrow;
    }
  }

  /// 3. Déclarer une entrée de stock (Requête)
  /// URL Serveur: POST /api/stock/requests/declare
  Future<void> declareStockEntry(Map<String, dynamic> data) async {
    try {
      await _apiService.client.post('/stock/requests/declare', data: data);
    } catch (e) {
      rethrow;
    }
  }

  /// 4. Enregistrer une vente (Sortie)
  /// URL Serveur: POST /api/stock/movements/sale
  Future<void> recordSale(Map<String, dynamic> saleData) async {
    try {
      await _apiService.client.post('/stock/movements/sale', data: saleData);
    } catch (e) {
      rethrow;
    }
  }

  /// 5. Récupérer l'historique des mouvements d'un produit
  /// URL Serveur: GET /api/stock/movements/product/:productId
  Future<List<dynamic>> getProductHistory(int productId) async {
    try {
      final response = await _apiService.client.get('/stock/movements/product/$productId');
      // Le backend renvoie un tableau d'objets (mouvements)
      return response.data; 
    } catch (e) {
      debugPrint("Erreur historique: $e");
      // On retourne une liste vide pour ne pas crasher l'UI
      return []; 
    }
  }
}