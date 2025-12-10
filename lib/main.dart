// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // AJOUT IMPORTANT POUR LA LANGUE

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
        // 1. Services (Couche basse)
        Provider<ApiService>(create: (_) => ApiService()),
        
        ProxyProvider<ApiService, AuthService>(
          update: (_, api, __) => AuthService(api),
        ),
        ProxyProvider<ApiService, ProductRepository>(
          update: (_, api, __) => ProductRepository(api),
        ),

        // 2. Providers d'État (Couche logique)
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
        theme: WinkTheme.themeData, // Thème Orange/Noir

        // --- CONFIGURATION LINGUISTIQUE (FRANÇAIS) ---
        // Nécessaire pour le calendrier et les formats de date
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('fr', 'FR'), // Force le Français partout
        ],
        // ----------------------------------------------

        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            // Vérification de session
            // Si un shop est chargé, on va au Dashboard, sinon au Login
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