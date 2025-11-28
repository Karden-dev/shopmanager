// lib/widgets/stock_product_card.dart

import 'package:flutter/material.dart';
import 'package:wink_merchant/models/product.dart';
import 'package:wink_merchant/utils/wink_theme.dart';
import 'package:wink_merchant/screens/product_details_screen.dart';

class StockProductCard extends StatelessWidget {
  final String productName;
  final List<Product> variants;

  const StockProductCard({
    super.key,
    required this.productName,
    required this.variants,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Calculs de synthèse
    int totalStock = 0;
    int totalAlertThreshold = 0;
    bool hasCriticalVariant = false; // Si UNE seule variante est critique -> Alerte Rouge
    double minPrice = double.infinity;
    double maxPrice = 0.0;

    for (var p in variants) {
      totalStock += p.quantity;
      totalAlertThreshold += p.alertThreshold;
      
      if (p.quantity <= p.alertThreshold) hasCriticalVariant = true;
      
      if (p.sellingPrice < minPrice) minPrice = p.sellingPrice;
      if (p.sellingPrice > maxPrice) maxPrice = p.sellingPrice;
    }

    String priceDisplay = (minPrice == maxPrice)
        ? "${minPrice.toStringAsFixed(0)} F"
        : "${minPrice.toStringAsFixed(0)} - ${maxPrice.toStringAsFixed(0)} F";

    // 2. Calcul Santé Globale
    // On considère le stock "Plein" s'il est à 3x le seuil global
    double globalProgress = 0.0;
    if (totalAlertThreshold > 0) {
      globalProgress = (totalStock / (totalAlertThreshold * 3)).clamp(0.0, 1.0);
    } else if (totalStock > 0) {
      globalProgress = 1.0;
    }

    Color statusColor = hasCriticalVariant ? WinkTheme.error : (globalProgress < 0.5 ? Colors.orange : WinkTheme.success);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: hasCriticalVariant ? Border.all(color: WinkTheme.error.withOpacity(0.3)) : null,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailsScreen(productName: productName, variants: variants)));
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Icône Catégorie (Visuel)
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.inventory_2_outlined, color: statusColor),
                    ),
                    const SizedBox(width: 16),
                    
                    // Infos
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(productName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text("$priceDisplay  •  ${variants.length} variante(s)", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),

                    // Badge Total
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("$totalStock", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: statusColor)),
                        Text("Total", style: TextStyle(fontSize: 10, color: statusColor.withOpacity(0.8))),
                      ],
                    )
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Barre de progression unique (Synthèse)
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: globalProgress,
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation(statusColor),
                  ),
                ),
                
                if (hasCriticalVariant)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 14, color: WinkTheme.error),
                        const SizedBox(width: 4),
                        Text("Rupture ou stock faible sur une variante", style: TextStyle(fontSize: 11, color: WinkTheme.error, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }
}