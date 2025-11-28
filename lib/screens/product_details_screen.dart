// lib/screens/product_details_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wink_merchant/models/product.dart';
import 'package:wink_merchant/repositories/product_repository.dart';
import 'package:wink_merchant/utils/wink_theme.dart';

class ProductDetailsScreen extends StatelessWidget {
  final String productName;
  final List<Product> variants;

  const ProductDetailsScreen({super.key, required this.productName, required this.variants});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8), // Fond gris clair moderne
      appBar: AppBar(
        title: Text(productName, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("Détail par Variante", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 16),

          // On génère une carte dépliante pour chaque variante du produit
          ...variants.map((variant) => _buildVariantDetailCard(context, variant)).toList(),
        ],
      ),
    );
  }

  Widget _buildVariantDetailCard(BuildContext context, Product variant) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), 
        side: BorderSide(color: Colors.grey.shade200)
      ),
      color: Colors.white,
      child: ExpansionTile(
        shape: Border.all(color: Colors.transparent), // Retire les bordures par défaut de l'ExpansionTile
        title: Text(
          variant.variant ?? "Standard",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
        ),
        subtitle: Text(
          "Stock: ${variant.quantity} | Prix: ${variant.sellingPrice.toStringAsFixed(0)} F",
          style: TextStyle(color: Colors.grey.shade600),
        ),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: WinkTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10)
          ),
          child: const Icon(Icons.inventory_2, color: WinkTheme.primary),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 10),
                
                // --- SECTION 1 : COMMANDES EN ATTENTE (Mock pour l'instant) ---
                // TODO: Connecter avec l'API des commandes si nécessaire
                _buildSectionTitle("Commandes en cours (Non validées)"),
                _buildPendingOrderItem("Commande #1024 (En attente)", 2),
                
                const SizedBox(height: 24),
                
                // --- SECTION 2 : HISTORIQUE RÉEL (Chargé via API) ---
                _buildSectionTitle("Historique des Mouvements"),
                
                FutureBuilder<List<dynamic>>(
                  // On appelle la méthode qu'on a ajoutée dans le Repository
                  future: Provider.of<ProductRepository>(context, listen: false).getProductHistory(variant.id),
                  builder: (ctx, snapshot) {
                     if (snapshot.connectionState == ConnectionState.waiting) {
                       return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                     }
                     if (snapshot.hasError) {
                       return const Text("Impossible de charger l'historique.", style: TextStyle(color: Colors.red));
                     }
                     if (!snapshot.hasData || snapshot.data!.isEmpty) {
                       return const Padding(
                         padding: EdgeInsets.symmetric(vertical: 10),
                         child: Text("Aucun mouvement récent.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                       );
                     }
                     
                     // On affiche les 5 derniers mouvements
                     final history = snapshot.data!.take(5).toList();
                     
                     return Column(
                       children: history.map((move) {
                         // Formatage basique de la date (YYYY-MM-DD)
                         String dateStr = "Date inconnue";
                         if (move['created_at'] != null) {
                           dateStr = move['created_at'].toString().split('T')[0];
                         }

                         return _buildHistoryItem(
                           move['type'] ?? 'Inconnu', 
                           int.tryParse(move['quantity'].toString()) ?? 0, 
                           dateStr
                         );
                       }).toList(),
                     );
                  }
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(), 
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0)
      ),
    );
  }

  // Widget pour une commande en attente (Visuel spécifique)
  Widget _buildPendingOrderItem(String label, int qty) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.pending_actions, size: 18, color: Colors.orange),
              const SizedBox(width: 10),
              Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: Colors.orange.shade800)),
            ],
          ),
          Text("- $qty unités", style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // Widget pour une ligne d'historique (Entrée/Sortie)
  Widget _buildHistoryItem(String type, int qty, String date) {
    bool isEntry = qty > 0;
    
    IconData icon;
    Color color;
    String label;

    // Traduction et style selon le type de mouvement
    if (type == 'sale') {
      icon = Icons.arrow_upward;
      color = WinkTheme.error; // Rouge pour sortie
      label = "Vente";
    } else if (type == 'entry') {
      icon = Icons.arrow_downward;
      color = WinkTheme.success; // Vert pour entrée
      label = "Entrée Stock";
    } else {
      icon = Icons.swap_horiz;
      color = Colors.blue;
      label = type; // Autres types (ajustement, retour...)
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Text(
            "${qty > 0 ? '+' : ''}$qty", 
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color)
          ),
        ],
      ),
    );
  }
}