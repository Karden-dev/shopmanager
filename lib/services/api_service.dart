// lib/services/api_service.dart

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wink_merchant/utils/constants.dart';

class ApiService {
  final Dio _dio = Dio();
  final _storage = const FlutterSecureStorage();

  ApiService() {
    _dio.options.baseUrl = AppConstants.baseUrl;
    
    // MODIFICATION : Augmentation des timeouts pour supporter l'upload d'images
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 60);
    _dio.options.sendTimeout = const Duration(seconds: 60); // Crucial pour l'upload

    // Intercepteur pour injecter le Token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'jwt_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        if (e.response?.statusCode == 401) {
          // TODO: Gérer la déconnexion forcée ici (rediriger vers Login)
          print("Token expiré ou invalide");
        }
        return handler.next(e);
      },
    ));
  }

  Dio get client => _dio;

  // --- NOUVELLE MÉTHODE : ENVOI DE FICHIERS (MULTIPART) ---
  Future<Response> postMultipart(String endpoint, FormData formData) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data', // Force le type MIME correct
        ),
      );
      return response;
    } catch (e) {
      // On relaie l'erreur pour qu'elle soit gérée par le Provider/UI
      rethrow;
    }
  }
}