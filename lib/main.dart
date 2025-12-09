// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Services
import 'package:wink_merchant/services/api_service.dart';
import 'package:wink_merchant/services/auth_service.dart';
import 'package:wink_merchant/services/database_service.dart';
import 'package:wink_merchant/repositories/product_repository.dart';
// Providers
import 'package:wink_merchant/providers/auth_provider.dart';
import 'package:wink_merchant/providers/stock_provider.dart';
// Ecrans & Thème
import 'package:wink_merchant/screens/login_screen.dart';
import 'package:wink_merchant/screens/dashboard_screen.dart';
import 'package:wink_merchant/utils/wink_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService().database; // Init BDD locale
  runApp(const WinkMerchantApp());
}

class WinkMerchantApp extends StatelessWidget {
  const WinkMerchantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 1. Services
        Provider<ApiService>(create: (_) => ApiService()),
        
        ProxyProvider<ApiService, AuthService>(
          update: (_, api, __) => AuthService(api),
        ),
        ProxyProvider<ApiService, ProductRepository>(
          update: (_, api, __) => ProductRepository(api),
        ),

        // 2. Providers d'État
        ChangeNotifierProxyProvider<AuthService, AuthProvider>(
          create: (context) => AuthProvider(Provider.of<AuthService>(context, listen: false)),
          update: (_, auth, prev) => AuthProvider(auth),
        ),
        ChangeNotifierProxyProvider<ProductRepository, StockProvider>(
          create: (context) => StockProvider(Provider.of<ProductRepository>(context, listen: false)),
          update: (_, repo, prev) => StockProvider(repo),
        ),
      ],
      child: MaterialApp(
        title: 'Wink Merchant',
        debugShowCheckedModeBanner: false,
        theme: WinkTheme.themeData, // Notre thème Orange/Noir
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            // CORRECTION ICI : Vérification sécurisée
            // Si on a un shop connecté, on va au Dashboard, sinon Login
            if (auth.currentShop != null) {
              return const DashboardScreen();
            } else {
              return const LoginScreen();
            }
          },
        ),
      ),
    );
  }
}