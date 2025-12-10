// lib/screens/product_details_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Pour les dates en français
import 'package:wink_merchant/models/product.dart';
import 'package:wink_merchant/repositories/product_repository.dart';
import 'package:wink_merchant/utils/wink_theme.dart';

class ProductDetailsScreen extends StatelessWidget {
  final String productName;
  final List<Product> variants;

  const ProductDetailsScreen({
    super.key, 
    required this.productName, 
    required this.variants
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(productName, style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // En-tête global
          Row(
            children: [
              const Icon(Icons.category_outlined, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                "${variants.length} variante(s) disponible(s)",
                style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Liste des variantes (Accordéons)
          ...variants.map((variant) => _buildVariantDetailCard(context, variant)),
        ],
      ),
    );
  }

  Widget _buildVariantDetailCard(BuildContext context, Product variant) {
    final bool isLowStock = variant.quantity <= variant.alertThreshold;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), 
        side: BorderSide(color: Colors.grey.shade200)
      ),
      color: Colors.white,
      clipBehavior: Clip.antiAlias, // Pour que l'image ne dépasse pas
      child: Theme(
        // Supprime les bordures par défaut de l'ExpansionTile
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(12),
          // --- IMAGE DE LA VARIANTE ---
          leading: Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: variant.imageUrl != null 
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(variant.imageUrl!, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.broken_image, size: 20, color: Colors.grey)),
                )
              : const Icon(Icons.image, color: Colors.grey),
          ),
          
          // --- TITRE ET STOCK ---
          title: Text(
            variant.variant ?? "Standard",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isLowStock ? Colors.red.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(4)
                  ),
                  child: Text(
                    "Stock: ${variant.quantity}",
                    style: TextStyle(
                      color: isLowStock ? Colors.red : Colors.green.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 12
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "${variant.sellingPrice.toStringAsFixed(0)} F",
                  style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          
          // --- CONTENU DÉPLIÉ (HISTORIQUE) ---
          children: [
            const Divider(height: 1),
            Container(
              color: const Color(0xFFFAFAFA), // Fond très léger pour le détail
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Réf SKU
                  if (variant.reference != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          const Icon(Icons.qr_code, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text("Réf: ${variant.reference}", style: const TextStyle(fontFamily: 'monospace', color: Colors.black87)),
                        ],
                      ),
                    ),

                  const Text("Derniers Mouvements", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 12),
                  
                  // Chargement Historique
                  FutureBuilder<List<dynamic>>(
                    future: Provider.of<ProductRepository>(context, listen: false).getProductHistory(variant.id),
                    builder: (ctx, snapshot) {
                       if (snapshot.connectionState == ConnectionState.waiting) {
                         return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(strokeWidth: 2)));
                       }
                       if (snapshot.hasError) {
                         return const Text("Erreur de chargement.", style: TextStyle(color: Colors.red));
                       }
                       if (!snapshot.hasData || snapshot.data!.isEmpty) {
                         return const Padding(
                           padding: EdgeInsets.symmetric(vertical: 10),
                           child: Text("Aucun historique disponible.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                         );
                       }
                       
                       // Affiche les 5 derniers
                       final history = snapshot.data!.take(5).toList();
                       
                       return Column(
                         children: history.map((move) => _buildHistoryTimelineItem(move)).toList(),
                       );
                    }
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTimelineItem(Map<String, dynamic> move) {
    final type = move['type'];
    final quantity = int.tryParse(move['quantity'].toString()) ?? 0;
    
    // Parsing Date (Sécure)
    DateTime date;
    try {
      date = DateTime.parse(move['created_at']);
    } catch (e) {
      date = DateTime.now();
    }
    final dateStr = DateFormat('dd MMM à HH:mm', 'fr_FR').format(date);

    // Config visuelle
    IconData icon;
    Color color;
    String label;
    String sign;

    switch (type) {
      case 'sale':
        icon = Icons.arrow_upward_rounded;
        color = Colors.red;
        label = "Vente";
        sign = ""; // Déjà négatif en base normalement, mais on affiche brut
        break;
      case 'entry':
        icon = Icons.arrow_downward_rounded;
        color = Colors.green;
        label = "Entrée Stock";
        sign = "+";
        break;
      case 'adjustment':
        icon = Icons.tune_rounded;
        color = Colors.orange;
        label = "Ajustement";
        sign = quantity > 0 ? "+" : "";
        break;
      default:
        icon = Icons.circle;
        color = Colors.grey;
        label = type.toString().toUpperCase();
        sign = "";
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date (Colonne gauche)
          SizedBox(
            width: 50,
            child: Text(
              DateFormat('dd/MM', 'fr_FR').format(date),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
            ),
          ),
          
          // Ligne de temps (Point + Trait)
          Column(
            children: [
              Container(
                width: 10, height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              Container(width: 2, height: 30, color: Colors.grey.shade200),
            ],
          ),
          const SizedBox(width: 12),

          // Détail Mouvement
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(
                      "$sign$quantity", 
                      style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)
                    ),
                  ],
                ),
                Text(
                  DateFormat('HH:mm', 'fr_FR').format(date),
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}