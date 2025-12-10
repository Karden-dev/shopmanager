// lib/screens/wip_screen.dart

import 'package:flutter/material.dart';
import 'package:wink_merchant/screens/dashboard_screen.dart'; // Assurez-vous que l'import est correct

class WipScreen extends StatelessWidget {
  final String title;
  
  const WipScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 20),
            Text(
              "Module en construction",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "Cette fonctionnalité sera disponible dans une prochaine mise à jour WINK Merchant.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 30),
            
            // --- BOUTON CORRIGÉ ---
            ElevatedButton.icon(
              icon: const Icon(Icons.home),
              label: const Text("Retour à l'accueil"),
              onPressed: () {
                // Vérifie si on peut revenir en arrière (pop)
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  // Sinon (si on vient du menu), on force le retour au Dashboard
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const DashboardScreen()),
                  );
                }
              },
            )
          ],
        ),
      ),
    );
  }
}