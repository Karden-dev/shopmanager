// lib/services/auth_service.dart

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wink_merchant/services/api_service.dart';

class AuthService {
  final ApiService _apiService;
  final _storage = const FlutterSecureStorage();

  AuthService(this._apiService);

  // Retourne une Map contenant 'shop' et 'token'
  Future<Map<String, dynamic>> login(String phone, String pin) async {
    try {
      final response = await _apiService.client.post('/shops/login', data: {
        'phone': phone,
        'pin': pin,
      });

      final data = response.data;
      final shopData = data['shop'];
      final token = data['token'];
      
      // 1. Sauvegarde Token (Sécurisé)
      await _storage.write(key: 'jwt_token', value: token);
      
      // 2. Sauvegarde Infos Shop (Persistance Locale)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('shop_data', jsonEncode(shopData));
      
      return {
        'shop': shopData,
        'token': token,
      };
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Erreur de connexion');
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('shop_data');
  }

  // Récupère les infos boutiques sauvegardées
  Future<Map<String, dynamic>?> getSavedShop() async {
    final prefs = await SharedPreferences.getInstance();
    final shopString = prefs.getString('shop_data');
    if (shopString != null) {
      return jsonDecode(shopString);
    }
    return null;
  }

  // Récupère le token sauvegardé
  Future<String?> getSavedToken() async {
    return await _storage.read(key: 'jwt_token');
  }
}