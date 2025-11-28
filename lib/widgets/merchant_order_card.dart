// lib/widgets/merchant_order_card.dart

import 'package:flutter/material.dart';
import 'package:wink_merchant/utils/wink_theme.dart';

class MerchantOrderCard extends StatelessWidget {
  final String orderId;
  final String firstItemName; 
  final String price;
  final String pickupLocation; 
  final String deliveryLocation; 
  final String status; 
  final String? deliverymanName; 
  final VoidCallback onTap;

  const MerchantOrderCard({
    super.key,
    required this.orderId,
    required this.firstItemName,
    required this.price,
    required this.pickupLocation,
    required this.deliveryLocation,
    required this.status,
    this.deliverymanName,
    required this.onTap,
  });

  // Helper pour déterminer le style (Couleurs douces)
  Map<String, dynamic> _getStatusStyle() {
    switch (status) {
      case 'delivered':
        // Vert Menthe / Forêt
        return {'color': const Color(0xFF2E7D32), 'bgColor': const Color(0xFFE8F5E9), 'progress': 1.0, 'label': 'Livrée'};
      case 'cancelled':
      case 'failed_delivery':
        // Rouge Brique / Pâle
        return {'color': const Color(0xFFC62828), 'bgColor': const Color(0xFFFFEBEE), 'progress': 1.0, 'label': 'Annulée'};
      case 'en_route':
        // Bleu Océan / Ciel
        return {'color': const Color(0xFF1565C0), 'bgColor': const Color(0xFFE3F2FD), 'progress': 0.75, 'label': 'En route'};
      case 'in_progress':
      case 'ready_for_pickup':
        // Orange Brûlé / Pâle
        return {'color': const Color(0xFFEF6C00), 'bgColor': const Color(0xFFFFF3E0), 'progress': 0.4, 'label': 'En cours'};
      default: 
        return {'color': Colors.grey.shade700, 'bgColor': Colors.grey.shade100, 'progress': 0.1, 'label': 'En attente'};
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _getStatusStyle();
    final Color color = style['color'];
    final Color bgColor = style['bgColor'];
    final double progress = style['progress'];
    final String label = style['label'];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20), // Coins plus arrondis
          border: Border.all(color: Colors.grey.shade100), // Bordure subtile
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- LIGNE 1 : EN-TÊTE ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        firstItemName,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF2D3436)),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text("ID: #$orderId", style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: WinkTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    price,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: WinkTheme.primary),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1, color: Color(0xFFF1F2F6)),
            ),

            // --- LIGNE 2 : TIMELINE STYLISÉE ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Colonne Visuelle
                Column(
                  children: [
                    const Icon(Icons.storefront, size: 14, color: Colors.grey),
                    // Pointillés verticaux
                    Container(
                      height: 24,
                      width: 1,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    const Icon(Icons.location_on, size: 14, color: WinkTheme.primary),
                  ],
                ),
                const SizedBox(width: 12),
                // Colonne Adresses
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pickupLocation, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 16), // Espace calculé
                      Text(deliveryLocation, style: const TextStyle(color: Color(0xFF2D3436), fontWeight: FontWeight.w700, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),

            // --- LIGNE 3 : PROGRESSION ---
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: bgColor, // Fond pastel
                valueColor: AlwaysStoppedAnimation<Color>(color), // Barre couleur forte
                minHeight: 6,
              ),
            ),
            
            const SizedBox(height: 16),

            // --- LIGNE 4 : STATUT & LIVREUR ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Badge Statut Pastel
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      // Petit point status
                      Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
                    ],
                  ),
                ),

                // Livreur
                if (deliverymanName != null)
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.grey.shade200,
                        child: Icon(Icons.person, size: 12, color: Colors.grey.shade700),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        deliverymanName!,
                        style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                    ],
                  )
                else
                  Text("En attente d'assignation", style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontStyle: FontStyle.italic)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}