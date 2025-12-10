// lib/providers/stock_provider.dart

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:wink_merchant/models/product.dart';
import 'package:wink_merchant/repositories/product_repository.dart';

class StockProvider with ChangeNotifier {
  final ProductRepository _repository;
  
  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;

  // Cache pour le journal des mouvements (Liste vide par défaut)
  List<dynamic> _journal = [];
  List<dynamic> get journal => _journal;

  StockProvider(this._repository);

  // Getters
  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get totalItems => _products.length;
  double get totalStockValue => _products.fold(0, (sum, item) => sum + (item.quantity * item.sellingPrice));

  // --- LOGIQUE DE REGROUPEMENT ---
  Map<String, List<Product>> get groupedProducts {
    final Map<String, List<Product>> groups = {};
    for (var product in _products) {
      if (!groups.containsKey(product.name)) {
        groups[product.name] = [];
      }
      groups[product.name]!.add(product);
    }
    return groups;
  }
  
  Map<String, List<Product>> searchGrouped(String query) {
    if (query.isEmpty) return groupedProducts;
    final lowerQuery = query.toLowerCase();
    
    final Map<String, List<Product>> filtered = {};
    groupedProducts.forEach((key, value) {
      if (key.toLowerCase().contains(lowerQuery) || 
          value.any((p) => (p.variant ?? '').toLowerCase().contains(lowerQuery))) {
        filtered[key] = value;
      }
    });
    return filtered;
  }

  // --- ACTIONS API ---

  Future<void> loadProducts(int shopId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _products = await _repository.getProducts(shopId);
    } catch (e) {
      _error = "Erreur chargement stock";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Product> createProduct(Map<String, dynamic> productData, {File? imageFile}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      dynamic dataToSend;
      if (imageFile != null) {
        dataToSend = FormData.fromMap({
          ...productData,
          'product_image': await MultipartFile.fromFile(imageFile.path),
        });
      } else {
        dataToSend = productData;
      }

      final newProduct = await _repository.createProduct(dataToSend);
      _products.add(newProduct); 
      return newProduct;
    } catch (e) {
      _error = "Erreur création";
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> addProduct(Map<String, dynamic> data, {File? imageFile}) async => 
      await createProduct(data, imageFile: imageFile);

  Future<void> declareEntry(Map<String, dynamic> entryData, {File? proofFile}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      dynamic dataToSend;
      if (proofFile != null) {
        dataToSend = FormData.fromMap({
          ...entryData,
          'proof_image': await MultipartFile.fromFile(proofFile.path),
        });
      } else {
        dataToSend = entryData;
      }
      await _repository.declareStockEntry(dataToSend);
    } catch (e) {
      _error = "Erreur déclaration";
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> recordSale(int shopId, int productId, int quantity) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.recordSale({
        'shop_id': shopId,
        'product_id': productId,
        'quantity': quantity,
      });

      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        final old = _products[index];
        _products[index] = Product(
          id: old.id,
          reference: old.reference,
          name: old.name,
          variant: old.variant,
          quantity: old.quantity - quantity,
          alertThreshold: old.alertThreshold,
          sellingPrice: old.sellingPrice,
          imageUrl: old.imageUrl,
        );
      }
    } catch (e) {
      _error = "Erreur vente";
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- NOUVEAU : Charger le Journal des Mouvements ---
  Future<void> fetchJournal(int shopId, {String? type, DateTime? start, DateTime? end, String? search}) async {
    _isLoading = true;
    notifyListeners();
    try {
      // Conversion des dates au format ISO (compatible backend)
      String? startStr = start?.toIso8601String();
      String? endStr = end?.toIso8601String();
      
      _journal = await _repository.getShopJournal(shopId, type: type, startDate: startStr, endDate: endStr, search: search);
    } catch (e) {
      _error = "Impossible de charger le journal";
      // On garde _journal vide en cas d'erreur
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- NOUVEAU : Récupérer les données brutes pour le rapport PDF ---
  Future<List<dynamic>> fetchInventoryReportData(int shopId) async {
    // Cette fonction ne change pas l'état de l'UI (pas de notifyListeners)
    // Elle sert juste de passe-plat pour l'écran d'export
    return await _repository.getInventoryReport(shopId);
  }
}