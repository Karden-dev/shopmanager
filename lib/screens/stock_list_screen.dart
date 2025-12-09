// lib/screens/stock_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wink_merchant/providers/stock_provider.dart';
import 'package:wink_merchant/providers/auth_provider.dart';
import 'package:wink_merchant/utils/wink_theme.dart';
import 'package:wink_merchant/screens/stock_create_screen.dart';
import 'package:wink_merchant/screens/stock_entry_screen.dart';
import 'package:wink_merchant/screens/stock_sale_screen.dart';
import 'package:wink_merchant/widgets/stock_product_card.dart';

class StockListScreen extends StatefulWidget {
  const StockListScreen({super.key});

  @override
  State<StockListScreen> createState() => _StockListScreenState();
}

class _StockListScreenState extends State<StockListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStock();
    });
  }

  void _loadStock() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.currentShop != null) {
      Provider.of<StockProvider>(context, listen: false).loadProducts(auth.currentShop!['id']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text("Gestion du Stock", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadStock),
        ],
      ),
      body: Column(
        children: [
          // Actions
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: _buildActionBtn(
                    "Sortie / Vente", Icons.qr_code_scanner, WinkTheme.success, 
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StockSaleScreen())).then((_) => _loadStock())
                  )
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionBtn(
                    "Entrée Stock", Icons.download_rounded, WinkTheme.primary, 
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StockEntryScreen())).then((_) => _loadStock())
                  )
                ),
              ],
            ),
          ),
          
          // Recherche
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Rechercher (Nom, Réf...)",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xFFF4F6F8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

          // Liste Groupée
          Expanded(
            child: Consumer<StockProvider>(
              builder: (context, stock, child) {
                if (stock.isLoading) return const Center(child: CircularProgressIndicator());
                
                final grouped = stock.searchGrouped(_searchQuery);
                if (grouped.isEmpty) return const Center(child: Text("Aucun produit.", style: TextStyle(color: Colors.grey)));

                final keys = grouped.keys.toList()..sort();

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: keys.length + 1, // +1 pour le bouton d'ajout en bas
                  itemBuilder: (ctx, index) {
                    if (index == keys.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 20, bottom: 40),
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StockCreateScreen())).then((_) => _loadStock()),
                          icon: const Icon(Icons.add),
                          label: const Text("AJOUTER UN NOUVEAU PRODUIT"),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                        ),
                      );
                    }
                    final name = keys[index];
                    return StockProductCard(productName: name, variants: grouped[name]!);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}