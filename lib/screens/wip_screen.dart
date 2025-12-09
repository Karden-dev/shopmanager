// lib/screens/wip_screen.dart

import 'package:flutter/material.dart';

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
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Retour"),
            )
          ],
        ),
      ),
    );
  }
}