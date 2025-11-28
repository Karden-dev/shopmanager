// lib/providers/auth_provider.dart

import 'package:flutter/material.dart';
import 'package:wink_merchant/services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  
  bool _isLoading = false;
  Map<String, dynamic>? _currentShop;

  AuthProvider(this._authService);

  bool get isLoading => _isLoading;
  Map<String, dynamic>? get currentShop => _currentShop;

  Future<void> login(String phone, String pin) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentShop = await _authService.login(phone, pin);
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
    notifyListeners();
  }
  
  // Vérification au démarrage
  Future<bool> checkAuth() async {
    return await _authService.isLoggedIn();
    // Idéalement, on appellerait une route /me pour récupérer le profil à jour
  }
}