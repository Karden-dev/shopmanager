// lib/repositories/product_repository.dart

import 'package:flutter/foundation.dart';
import 'package:wink_merchant/services/api_service.dart';
import 'package:wink_merchant/services/database_service.dart';
import 'package:wink_merchant/models/product.dart';

class ProductRepository {
  final ApiService _apiService;
  final DatabaseService _dbService = DatabaseService();

  ProductRepository(this._apiService);

  /// 1. Récupère les produits
  Future<List<Product>> getProducts(int shopId) async {
    try {
      final response = await _apiService.client.get('/products/shop/$shopId');
      final List<dynamic> serverData = response.data;
      
      // Cache local
      await _dbService.batchInsertProducts(serverData);
      
      return serverData.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      debugPrint("Mode Offline ou Erreur API : ${e.toString()}");
      final localData = await _dbService.getAllProducts();
      return localData.map((json) => Product.fromJson(json)).toList();
    }
  }

  /// 2. Création d'un produit (Compatible Map JSON ou FormData Fichier)
  Future<Product> createProduct(dynamic productData) async {
    try {
      final response = await _apiService.client.post('/products', data: productData);
      return Product.fromJson(response.data); 
    } catch (e) {
      rethrow;
    }
  }

  /// 3. Déclarer une entrée de stock
  Future<void> declareStockEntry(dynamic data) async {
    try {
      await _apiService.client.post('/stock/requests/declare', data: data);
    } catch (e) {
      rethrow;
    }
  }

  /// 4. Enregistrer une vente
  Future<void> recordSale(Map<String, dynamic> saleData) async {
    try {
      await _apiService.client.post('/stock/movements/sale', data: saleData);
    } catch (e) {
      rethrow;
    }
  }

  /// 5. Historique d'un produit spécifique
  Future<List<dynamic>> getProductHistory(int productId) async {
    try {
      final response = await _apiService.client.get('/stock/movements/product/$productId');
      return response.data; 
    } catch (e) {
      debugPrint("Erreur historique: $e");
      return []; 
    }
  }

  /// 6. NOUVEAU : Journal Global de la Boutique (Avec Filtres)
  /// URL: GET /api/stock/movements/shop/:shopId
  Future<List<dynamic>> getShopJournal(int shopId, {String? type, String? startDate, String? endDate, String? search}) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (type != null && type != 'all') queryParams['type'] = type;
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _apiService.client.get(
        '/stock/movements/shop/$shopId', 
        queryParameters: queryParams
      );
      return response.data; 
    } catch (e) {
      debugPrint("Erreur Journal Global: $e");
      // On retourne une liste vide en cas d'erreur pour ne pas bloquer l'UI
      return [];
    }
  }

  /// 7. NOUVEAU : Rapport d'Inventaire Complet (Pour le PDF)
  /// URL: GET /api/stock/reports/inventory/:shopId
  Future<List<dynamic>> getInventoryReport(int shopId) async {
    try {
      final response = await _apiService.client.get('/stock/reports/inventory/$shopId');
      return response.data;
    } catch (e) {
      debugPrint("Erreur Rapport Inventaire: $e");
      throw Exception("Impossible de générer les données du rapport.");
    }
  }
}