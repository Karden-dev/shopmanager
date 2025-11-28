// lib/providers/stock_provider.dart

import 'package:flutter/material.dart';
import 'package:wink_merchant/models/product.dart';
import 'package:wink_merchant/repositories/product_repository.dart';

class StockProvider with ChangeNotifier {
  final ProductRepository _repository;
  
  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;

  StockProvider(this._repository);

  // Getters
  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get totalItems => _products.length;
  double get totalStockValue => _products.fold(0, (sum, item) => sum + (item.quantity * item.sellingPrice));

  // --- LOGIQUE DE REGROUPEMENT (Cœur de la mise à jour) ---

  /// 1. Regroupe les variantes sous un même nom parent
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
  
  /// 2. Recherche intelligente dans les groupes
  Map<String, List<Product>> searchGrouped(String query) {
    if (query.isEmpty) return groupedProducts;
    final lowerQuery = query.toLowerCase();
    
    final Map<String, List<Product>> filtered = {};
    groupedProducts.forEach((key, value) {
      // On garde le groupe si le NOM matche OU si une VARIANTE matche
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

  Future<Product> createProduct(Map<String, dynamic> productData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final newProduct = await _repository.createProduct(productData);
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
  
  // Alias pour compatibilité
  Future<void> addProduct(Map<String, dynamic> data) async => await createProduct(data);

  Future<void> declareEntry(Map<String, dynamic> entryData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.declareStockEntry(entryData);
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

      // Mise à jour locale optimiste
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
}