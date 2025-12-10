// lib/widgets/merchant_drawer.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wink_merchant/providers/auth_provider.dart';
import 'package:wink_merchant/screens/dashboard_screen.dart';
import 'package:wink_merchant/screens/stock_list_screen.dart';
import 'package:wink_merchant/screens/wip_screen.dart'; 

class MerchantDrawer extends StatelessWidget {
  final int selectedIndex; // AJOUTÉ : Pour savoir sur quelle page on est

  const MerchantDrawer({
    super.key, 
    this.selectedIndex = 0 // Par défaut sur le dashboard (0)
  });

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final shop = auth.currentShop;
    final shopName = shop?['name'] ?? 'Ma Boutique';
    final shopPhone = shop?['phone'] ?? '';
    final initial = shopName.isNotEmpty ? shopName.substring(0, 1).toUpperCase() : 'M';

    const winkPrimary = Color(0xFFFF9900); 

    return Drawer(
      child: Column(
        children: [
          // --- EN-TÊTE ---
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: winkPrimary),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                initial,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: winkPrimary),
              ),
            ),
            accountName: Text(shopName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            accountEmail: Text(shopPhone, style: const TextStyle(color: Colors.white70)),
          ),
          
          // --- MENU ---
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildNavItem(
                  context, 
                  index: 0, 
                  icon: Icons.dashboard_outlined, 
                  label: 'Tableau de bord', 
                  target: const DashboardScreen(),
                  color: Colors.black87
                ),
                
                const Divider(),
                
                _buildNavItem(
                  context, 
                  index: 2, // Index arbitraire pour Stock
                  icon: Icons.inventory_2_outlined, 
                  label: 'Mon Stock', 
                  target: const StockListScreen(),
                  color: Colors.blue
                ),
                
                _buildNavItem(
                  context, 
                  index: 3, 
                  icon: Icons.local_shipping_outlined, 
                  label: 'Mes Courses', 
                  target: const WipScreen(title: "Historique des Courses"),
                  color: Colors.orange
                ),

                _buildNavItem(
                  context, 
                  index: 4, 
                  icon: Icons.account_balance_wallet_outlined, 
                  label: 'Mes Finances', 
                  target: const WipScreen(title: "Comptabilité"),
                  color: Colors.green
                ),

                const Divider(),

                _buildNavItem(
                  context, 
                  index: 5, 
                  icon: Icons.settings_outlined, 
                  label: 'Paramètres', 
                  target: const WipScreen(title: "Réglages"),
                  color: Colors.grey
                ),
              ],
            ),
          ),

          // --- LOGOUT ---
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Déconnexion', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
            onTap: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Helper pour éviter la répétition
  Widget _buildNavItem(BuildContext context, {
    required int index, 
    required IconData icon, 
    required String label, 
    required Widget target,
    required Color color
  }) {
    final isSelected = index == selectedIndex;
    return ListTile(
      selected: isSelected,
      selectedTileColor: color.withOpacity(0.1),
      leading: Icon(icon, color: isSelected ? color : Colors.grey),
      title: Text(
        label, 
        style: TextStyle(
          color: isSelected ? color : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
        )
      ),
      onTap: () {
        Navigator.pop(context);
        if (!isSelected) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => target));
        }
      },
    );
  }
}