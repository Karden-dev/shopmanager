// lib/utils/wink_theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WinkTheme {
  // --- PALETTE DE COULEURS WINK ---
  static const Color primary = Color(0xFFFF9900); // Orange WINK (Ajustez le Hex si besoin)
  static const Color primaryDark = Color(0xFFE65100); 
  static const Color secondary = Color(0xFF212121); // Noir/Gris très sombre pour le contraste
  static const Color background = Color(0xFFF4F6F8); // Gris très clair (Moderne)
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);

  // --- THÈME GLOBAL ---
  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        surface: surface,
        background: background,
        error: error,
      ),
      scaffoldBackgroundColor: background,
      
      // Typographie
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        headlineLarge: const TextStyle(fontWeight: FontWeight.bold, color: secondary),
        titleLarge: const TextStyle(fontWeight: FontWeight.bold, color: secondary),
        bodyLarge: const TextStyle(color: Color(0xFF424242)),
      ),

      // App Bar
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: secondary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(color: secondary, fontSize: 20, fontWeight: FontWeight.bold),
      ),

      // Boutons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      
      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primary, width: 2)),
        labelStyle: TextStyle(color: Colors.grey.shade600),
        prefixIconColor: Colors.grey.shade500,
      ),
    );
  }
}