// lib/screens/stock_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wink_merchant/providers/stock_provider.dart';
import 'package:wink_merchant/providers/auth_provider.dart';
// Ecrans d'action
import 'package:wink_merchant/screens/stock_entry_screen.dart';
import 'package:wink_merchant/screens/stock_create_screen.dart';
import 'package:wink_merchant/screens/stock_sale_screen.dart';
import 'package:wink_merchant/screens/stock_history_screen.dart';
import 'package:wink_merchant/screens/stock_journal_screen.dart';
// Widgets & Utils
import 'package:wink_merchant/widgets/merchant_drawer.dart';
import 'package:wink_merchant/widgets/stock_product_card.dart';
import 'package:wink_merchant/utils/wink_theme.dart';
import 'package:wink_merchant/services/pdf_stock_service.dart';

class StockListScreen extends StatefulWidget {
  const StockListScreen({super.key});

  @override
  State<StockListScreen> createState() => _StockListScreenState();
}

class _StockListScreenState extends State<StockListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshStock();
    });
  }

  Future<void> _refreshStock() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.currentShop != null) {
      await Provider.of<StockProvider>(context, listen: false).loadProducts(auth.currentShop!['id']);
    }
  }

  Future<void> _exportPdf() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final stock = Provider.of<StockProvider>(context, listen: false);
    
    final shopId = auth.currentShop?['id'];
    final shopName = auth.currentShop?['name'] ?? "Ma Boutique";

    if (shopId == null) return;

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Génération du rapport en cours...")));

    try {
      final reportData = await stock.fetchInventoryReportData(shopId);

      // CORRECTION : Vérifier si le widget est toujours actif avant d'utiliser le contexte
      if (!mounted) return;

      if (reportData.isEmpty) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Aucune donnée à exporter.")));
         return;
      }

      await PdfStockService.generateInventoryReport(shopName, reportData);

    } catch (e) {
      // CORRECTION : Vérification ici aussi
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur Export: $e"), backgroundColor: Colors.red));
    }
  }

  // --- MENU D'ACTIONS RAPIDES ---
  void _showQuickActionsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Text("Que voulez-vous faire ?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                
                // 1. NOUVELLE VENTE
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade50,
                    child: Icon(Icons.shopping_bag_outlined, color: Colors.blue.shade800),
                  ),
                  title: const Text("Enregistrer une Vente", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text("Sortie de stock"),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const StockSaleScreen()));
                  },
                ),
                
                // 2. ENTRÉE STOCK
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.shade50,
                    child: Icon(Icons.add_shopping_cart, color: Colors.orange.shade800),
                  ),
                  title: const Text("Nouvel Arrivage", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text("Entrée de stock avec preuve"),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const StockEntryScreen()));
                  },
                ),

                const Divider(),

                // 3. CRÉER PRODUIT
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.shade50,
                    child: Icon(Icons.add_box_outlined, color: Colors.green.shade800),
                  ),
                  title: const Text("Créer un Nouveau Produit", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text("Ajouter une référence au catalogue"),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const StockCreateScreen()));
                  },
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WinkTheme.surface,
      appBar: AppBar(
        title: const Text("Mon Stock"),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: "Imprimer l'inventaire",
            onPressed: _exportPdf,
          ),
          IconButton(
            icon: const Icon(Icons.history_edu_outlined),
            tooltip: "Journal de bord",
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StockJournalScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.playlist_add_check),
            tooltip: "Suivi des validations",
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StockHistoryScreen())),
          ),
        ],
      ),
      drawer: const MerchantDrawer(selectedIndex: 2),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: "Rechercher un produit...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),

          // Liste
          Expanded(
            child: Consumer<StockProvider>(
              builder: (context, stock, child) {
                if (stock.isLoading) return const Center(child: CircularProgressIndicator());
                if (stock.error != null) return Center(child: Text("Erreur: ${stock.error}"));

                final groups = stock.searchGrouped(_searchQuery);

                if (groups.isEmpty) {
                  return const Center(child: Text("Aucun produit trouvé."));
                }

                return RefreshIndicator(
                  onRefresh: _refreshStock,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: groups.length,
                    itemBuilder: (ctx, index) {
                      final productName = groups.keys.elementAt(index);
                      final variants = groups[productName]!;
                      
                      // NOTE : StockProductCard doit accepter List<Product> maintenant
                      return StockProductCard(
                        productName: productName,
                        variants: variants,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      
      // BOUTON ACTION FLOTTANT
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showQuickActionsModal(context),
        backgroundColor: WinkTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("ACTION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}