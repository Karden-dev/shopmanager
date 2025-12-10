// lib/screens/stock_sale_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wink_merchant/providers/stock_provider.dart';
import 'package:wink_merchant/providers/auth_provider.dart';
import 'package:wink_merchant/models/product.dart';
import 'package:wink_merchant/utils/wink_theme.dart';
import 'package:wink_merchant/widgets/common/wink_dialog.dart';

class StockSaleScreen extends StatefulWidget {
  const StockSaleScreen({super.key});

  @override
  State<StockSaleScreen> createState() => _StockSaleScreenState();
}

class _StockSaleScreenState extends State<StockSaleScreen> {
  // État de la sélection
  String? _selectedProductName;
  List<Product> _variants = [];
  
  // Contrôleurs (Map: ID Produit -> Controller)
  final Map<int, TextEditingController> _qtyControllers = {};
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // On charge le stock à jour en entrant
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.currentShop != null) {
        Provider.of<StockProvider>(context, listen: false).loadProducts(auth.currentShop!['id']);
      }
    });
  }

  @override
  void dispose() {
    for (var c in _qtyControllers.values) c.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onProductSelected(String productName) {
    setState(() {
      _selectedProductName = productName;
      _qtyControllers.clear();
      
      final stock = Provider.of<StockProvider>(context, listen: false);
      _variants = stock.groupedProducts[productName] ?? [];
      
      for (var p in _variants) {
        _qtyControllers[p.id] = TextEditingController();
      }
    });
  }

  Future<void> _submit() async {
    // Vérification qu'au moins une quantité est saisie
    if (_qtyControllers.values.every((c) => c.text.isEmpty || c.text == "0")) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Aucune quantité vendue saisie"), backgroundColor: Colors.orange));
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final stock = Provider.of<StockProvider>(context, listen: false);
    final shopId = auth.currentShop?['id'];

    if (shopId == null) return;

    // Confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmer la vente"),
        content: const Text("Voulez-vous vraiment déduire ces quantités du stock ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: WinkTheme.primary, foregroundColor: Colors.white),
            child: const Text("Confirmer"),
          )
        ],
      )
    );

    if (confirm != true) return;

    try {
      int count = 0;
      for (var entry in _qtyControllers.entries) {
        final qty = int.tryParse(entry.value.text) ?? 0;
        if (qty > 0) {
          await stock.recordSale(shopId, entry.key, qty);
          count++;
        }
      }

      if (mounted) {
        WinkDialog.show(context, dialog: WinkDialog.success(
          title: "Vente Enregistrée",
          message: "$count lignes de stock mises à jour.",
          onPressed: () {
            Navigator.pop(context); // Ferme Dialog
            Navigator.pop(context); // Retour Liste
          },
        ));
      }

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Sortie de Stock (Vente)"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. RECHERCHE (Carte Blanche)
            _buildSectionCard(
              title: "Qu'avez-vous vendu ?",
              child: Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text == '') return const Iterable<String>.empty();
                  return Provider.of<StockProvider>(context, listen: false)
                      .searchGrouped(textEditingValue.text).keys;
                },
                onSelected: _onProductSelected,
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      hintText: "Nom du produit...",
                      prefixIcon: const Icon(Icons.search, color: Colors.blue), // Bleu pour la vente
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // 2. LISTE DES VARIANTES
            if (_selectedProductName != null) ...[
              Text("Sélectionnez les quantités vendues :", style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              
              ..._variants.map((p) => _buildSaleRow(p)),

              const SizedBox(height: 30),

              // 3. BOUTON ACTION
              Consumer<StockProvider>(
                builder: (ctx, stock, _) {
                  return SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: stock.isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700, // Bleu pour différencier de l'entrée (Orange)
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: stock.isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("VALIDER LA SORTIE", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ),
                  );
                }
              ),
            ] else 
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 50.0),
                  child: Column(
                    children: [
                      Icon(Icons.shopping_bag_outlined, size: 60, color: Colors.grey.shade300),
                      const SizedBox(height: 10),
                      const Text("Recherchez un produit pour commencer", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildSaleRow(Product p) {
    final controller = _qtyControllers[p.id];
    final bool isLowStock = p.quantity <= p.alertThreshold;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          // Info Variante
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.variant ?? "Standard", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.inventory_2, size: 14, color: isLowStock ? Colors.red : Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      "Stock dispo : ${p.quantity}", 
                      style: TextStyle(color: isLowStock ? Colors.red : Colors.green, fontWeight: FontWeight.bold, fontSize: 13)
                    ),
                  ],
                ),
                Text("${p.sellingPrice.toStringAsFixed(0)} F", style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          
          // Input Qté
          Container(
            width: 110,
            decoration: BoxDecoration(
              color: Colors.grey[50], 
              borderRadius: BorderRadius.circular(8), 
              border: Border.all(color: Colors.blue.shade100, width: 1.5)
            ),
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue.shade900),
              decoration: const InputDecoration(
                hintText: "0",
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}