// lib/widgets/merchant_drawer.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wink_merchant/providers/auth_provider.dart';
// --- ÉCRANS ---
import 'package:wink_merchant/screens/dashboard_screen.dart';
import 'package:wink_merchant/screens/stock_list_screen.dart';
import 'package:wink_merchant/screens/wip_screen.dart'; 

class MerchantDrawer extends StatelessWidget {
  const MerchantDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // Récupération des infos de la boutique connectée
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final shop = auth.currentShop;
    final shopName = shop?['name'] ?? 'Ma Boutique';
    final shopPhone = shop?['phone'] ?? '';
    final initial = shopName.isNotEmpty ? shopName.substring(0, 1).toUpperCase() : 'M';

    // Couleur WINK (Orange)
    const winkPrimary = Color(0xFFFF9900); 

    return Drawer(
      child: Column(
        children: [
          // --- EN-TÊTE PROFIL ---
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: winkPrimary,
              // On peut ajouter une image de fond légère si dispo
              // image: DecorationImage(image: AssetImage('assets/bg_header.png'), fit: BoxFit.cover, opacity: 0.2),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                initial,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: winkPrimary),
              ),
            ),
            accountName: Text(
              shopName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail: Text(
              shopPhone,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          
          // --- LISTE DE NAVIGATION ---
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // 1. TABLEAU DE BORD
                ListTile(
                  leading: const Icon(Icons.dashboard_outlined, color: Colors.black87),
                  title: const Text('Tableau de bord'),
                  onTap: () {
                    Navigator.pop(context); // Ferme le drawer
                    Navigator.pushReplacement(
                      context, 
                      MaterialPageRoute(builder: (_) => const DashboardScreen())
                    );
                  },
                ),
                
                const Divider(),
                
                // 2. GESTION DE STOCK
                ListTile(
                  leading: const Icon(Icons.inventory_2_outlined, color: Colors.blue),
                  title: const Text('Mon Stock'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (_) => const StockListScreen())
                    );
                  },
                ),
                
                // 3. MES COURSES (WIP)
                ListTile(
                  leading: const Icon(Icons.local_shipping_outlined, color: Colors.orange),
                  title: const Text('Mes Courses'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (_) => const WipScreen(title: "Historique des Courses"))
                    );
                  },
                ),

                // 4. FINANCES (WIP)
                ListTile(
                  leading: const Icon(Icons.account_balance_wallet_outlined, color: Colors.green),
                  title: const Text('Mes Finances'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (_) => const WipScreen(title: "Comptabilité & Versements"))
                    );
                  },
                ),

                const Divider(),

                // 5. PARAMÈTRES (WIP)
                ListTile(
                  leading: const Icon(Icons.settings_outlined, color: Colors.grey),
                  title: const Text('Paramètres'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (_) => const WipScreen(title: "Réglages Boutique"))
                    );
                  },
                ),
                 // 6. SUPPORT (WIP)
                ListTile(
                  leading: const Icon(Icons.headset_mic_outlined, color: Colors.pink),
                  title: const Text('Support Wink'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Service Support : Contactez le 690..."))
                    );
                  },
                ),
              ],
            ),
          ),

          // --- DÉCONNEXION ---
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Déconnexion', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
            onTap: () async {
              // Action de logout
              await auth.logout();
              if (context.mounted) {
                // Retour forcé à l'écran de login (vide la stack)
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}