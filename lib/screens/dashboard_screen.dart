import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wink_merchant/providers/auth_provider.dart';
import 'package:wink_merchant/widgets/merchant_drawer.dart';
import 'package:wink_merchant/widgets/merchant_order_card.dart';
import 'package:wink_merchant/screens/wip_screen.dart';
import 'package:wink_merchant/utils/wink_theme.dart'; // Assurez-vous d'avoir créé ce fichier thème

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final shopName = auth.currentShop?['name'] ?? 'Ma Boutique';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8), // Gris très clair pro
      
      // --- APP BAR ---
      appBar: AppBar(
        title: const Text(
          "Wink Merchant", 
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: Colors.black87)
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 28),
                onPressed: () {},
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    color: WinkTheme.error, // Rouge alerte
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              )
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      
      drawer: const MerchantDrawer(),

      // --- BOUTON FLOTTANT (AJOUT COMMANDE) ---
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigation vers création de commande (WIP ou écran existant)
          Navigator.push(context, MaterialPageRoute(builder: (_) => const WipScreen(title: "Nouvelle Course")));
        },
        backgroundColor: WinkTheme.primary, // Orange WINK
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 32),
      ),
      
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            RichText(
              text: TextSpan(
                text: 'Bonjour, ',
                style: const TextStyle(color: Colors.grey, fontSize: 16, fontFamily: 'Poppins'),
                children: [
                  TextSpan(
                    text: shopName,
                    style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w900, fontSize: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- 1. SUPER CARTE STATISTIQUES (Design Orange WINK) ---
            _buildHeroStatCard(context),

            const SizedBox(height: 30),

            // --- 2. LISTE DES COURSES ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Mes Courses", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WipScreen(title: "Historique"))),
                  child: const Text("Voir tout", style: TextStyle(color: WinkTheme.primary, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            
            // Liste des cartes
            _buildOrderList(context),
            
            // Espace pour le FAB
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // --- WIDGET : CARTE HERO (STYLE WINK) ---
  Widget _buildHeroStatCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        // Dégradé Orange WINK
        gradient: const LinearGradient(
          colors: [Color(0xFFFF9900), Color(0xFFE65100)], 
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFFFF9900).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Stack(
        children: [
          // Décoration de fond (Cercle transparent)
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 150, height: 150,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête Carte
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.analytics_outlined, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 8),
                        const Text("ACTIVITÉ DU JOUR", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                      ],
                    ),
                    // Petit badge pourcentage (Exemple)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                      child: const Text("+12%", style: TextStyle(color: Color(0xFFE65100), fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),

                // Montant Principal
                const Text("Montant Attendu", style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                const Text(
                  "125 000 FCFA", 
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, height: 1.0)
                ),
                
                const SizedBox(height: 24),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 16),

                // Indicateurs "Bulles"
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildGlassBadge("12", "Total"),
                    _buildGlassBadge("4", "En cours"),
                    _buildGlassBadge("8", "Livrées"),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassBadge(String value, String label) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  // --- WIDGET : LISTE DES COMMANDES ---
  Widget _buildOrderList(BuildContext context) {
    // Données fictives pour le design
    final orders = [
      {
        'id': '9021',
        'item': 'Menu Whopper x2 + Frites',
        'price': '8 500 F',
        'from': 'Ma Boutique',
        'to': 'Immeuble T. (Omnisport)',
        'status': 'en_route',
        'rider': 'Paul K.'
      },
      {
        'id': '9020',
        'item': 'Pizza Reine (Large)',
        'price': '6 000 F',
        'from': 'Ma Boutique',
        'to': 'Mvan Complex',
        'status': 'delivered',
        'rider': 'Jean M.'
      },
      {
        'id': '9019',
        'item': 'Salade César',
        'price': '3 000 F',
        'from': 'Ma Boutique',
        'to': 'Emana Pont',
        'status': 'cancelled',
        'rider': null
      },
    ];

    return Column(
      children: orders.map((data) {
        return MerchantOrderCard(
          orderId: data['id']!,
          firstItemName: data['item']!,
          price: data['price']!,
          pickupLocation: data['from']!,
          deliveryLocation: data['to']!,
          status: data['status']!,
          deliverymanName: data['rider'],
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const WipScreen(title: "Détails Commande")));
          },
        );
      }).toList(),
    );
  }
}