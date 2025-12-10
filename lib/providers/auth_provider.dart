// lib/providers/auth_provider.dart

import 'package:flutter/material.dart';
import 'package:wink_merchant/services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  
  bool _isLoading = false;
  Map<String, dynamic>? _currentShop;
  String? _token; // Ajout du token en mémoire

  // Injection du service via le constructeur
  AuthProvider(this._authService);

  bool get isLoading => _isLoading;
  Map<String, dynamic>? get currentShop => _currentShop;
  String? get token => _token; // Getter requis par StockProvider
  bool get isAuthenticated => _token != null;

  // Tentative de reconnexion automatique au démarrage
  Future<bool> tryAutoLogin() async {
    _isLoading = true;
    notifyListeners();

    try {
      final savedShop = await _authService.getSavedShop();
      final savedToken = await _authService.getSavedToken();

      if (savedShop != null && savedToken != null) {
        _currentShop = savedShop;
        _token = savedToken;
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Erreur AutoLogin: $e");
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> login(String phone, String pin) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _authService.login(phone, pin);
      _currentShop = result['shop'];
      _token = result['token'];
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentShop = null;
    _token = null;
    notifyListeners();
  }
}