// lib/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:wink_merchant/providers/auth_provider.dart';
import 'package:wink_merchant/screens/dashboard_screen.dart';
import 'package:wink_merchant/screens/login_screen.dart';
import 'package:wink_merchant/utils/wink_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    
    // Configuration de l'animation
    _controller = AnimationController(
      duration: const Duration(seconds: 4), // On laisse 4 secondes pour bien voir l'anim
      vsync: this,
    );

    // Écouteur : Quand l'animation est finie, on navigue
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _checkAuthAndNavigate();
      }
    });
    
    // Démarrer l'animation
    _controller.forward();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Vérification de l'état de connexion via le Provider
    // On utilise listen: false car on veut juste lire l'état, pas reconstruire la vue
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // On tente de récupérer le token stocké (si votre AuthProvider a une méthode tryAutoLogin, c'est le moment)
    // Sinon, on vérifie juste si le shop est déjà chargé
    bool isLoggedIn = authProvider.currentShop != null || authProvider.token != null;

    if (mounted) {
      // Navigation fluide sans retour possible (pushReplacement)
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => isLoggedIn 
              ? const DashboardScreen() 
              : const LoginScreen(),
          transitionDuration: const Duration(milliseconds: 800),
          transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, 
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- ANIMATION LOTTIE ---
            Lottie.asset(
              'assets/animations/splash.json', // Assurez-vous que ce fichier existe
              controller: _controller,
              height: 250,
              width: 250,
              fit: BoxFit.contain,
              onLoaded: (composition) {
                // Ajuste la durée du contrôleur sur la durée réelle du fichier JSON si besoin
                _controller.duration = composition.duration;
                _controller.forward();
              },
              errorBuilder: (context, error, stackTrace) {
                // Fallback si le fichier Lottie n'est pas trouvé ou corrompu
                return const Icon(
                  Icons.store_mall_directory_rounded, 
                  size: 100, 
                  color: WinkTheme.primary
                );
              },
            ),
            
            const SizedBox(height: 30),
            
            // --- TEXTE DE MARQUE ---
            Column(
              children: [
                Text(
                  "WINK EXPRESS",
                  style: TextStyle(
                    fontSize: 24, 
                    fontWeight: FontWeight.w900, 
                    color: Colors.black87,
                    letterSpacing: 2.0,
                    fontFamily: 'OpenSans', // Si vous utilisez cette police
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Partenaire Marchand",
                  style: TextStyle(
                    fontSize: 14, 
                    color: Colors.grey.shade600,
                    letterSpacing: 1.2
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}