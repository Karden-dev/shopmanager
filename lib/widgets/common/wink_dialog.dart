// lib/widgets/common/wink_dialog.dart

import 'package:flutter/material.dart';
import 'package:wink_merchant/utils/wink_theme.dart';

class WinkDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback onPressed;
  final IconData icon;
  final Color iconColor;

  const WinkDialog({
    super.key,
    required this.title,
    required this.message,
    this.buttonText = "D'accord",
    required this.onPressed,
    this.icon = Icons.check_circle,
    this.iconColor = WinkTheme.success,
  });

  // Constructeur nommé pour le succès
  factory WinkDialog.success({
    required String title,
    required String message,
    required VoidCallback onPressed,
  }) {
    return WinkDialog(
      title: title,
      message: message,
      onPressed: onPressed,
      icon: Icons.check_circle_outline,
      iconColor: WinkTheme.success,
    );
  }

  // Constructeur nommé pour l'erreur/alerte
  factory WinkDialog.alert({
    required String title,
    required String message,
    required VoidCallback onPressed,
  }) {
    return WinkDialog(
      title: title,
      message: message,
      onPressed: onPressed,
      icon: Icons.error_outline,
      iconColor: WinkTheme.error,
      buttonText: "Compris",
    );
  }

  static void show(BuildContext context, {required WinkDialog dialog}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => dialog,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icône animée ou statique
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: iconColor),
            ),
            const SizedBox(height: 20),
            
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: WinkTheme.secondary),
            ),
            const SizedBox(height: 8),
            
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: WinkTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(buttonText.toUpperCase()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}