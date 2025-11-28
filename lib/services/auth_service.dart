// lib/services/auth_service.dart

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart'; // AJOUT
import 'package:wink_merchant/services/api_service.dart';

class AuthService {
  final ApiService _apiService;
  final _storage = const FlutterSecureStorage();

  AuthService(this._apiService);

  Future<Map<String, dynamic>> login(String phone, String pin) async {
    try {
      final response = await _apiService.client.post('/shops/login', data: {
        'phone': phone,
        'pin': pin,
      });

      final data = response.data;
      final shopData = data['shop'];
      
      // 1. Sauvegarde Token (Sécurisé)
      await _storage.write(key: 'jwt_token', value: data['token']);
      
      // 2. Sauvegarde Infos Shop (Persistance Locale)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('shop_data', jsonEncode(shopData));
      
      return shopData;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Erreur de connexion');
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('shop_data');
  }

  // Nouvelle méthode pour récupérer le profil sauvegardé au démarrage
  Future<Map<String, dynamic>?> getSavedShop() async {
    final prefs = await SharedPreferences.getInstance();
    final shopString = prefs.getString('shop_data');
    if (shopString != null) {
      return jsonDecode(shopString);
    }
    return null;
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'jwt_token');
    return token != null;
  }
}