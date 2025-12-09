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
  String? _selectedProductName;
  List<Product> _variants = [];
  final Map<int, TextEditingController> _qtyControllers = {};

  @override
  void initState() {
    super.initState();
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
    final stock = Provider.of<StockProvider>(context, listen: false);
    final shopId = Provider.of<AuthProvider>(context, listen: false).currentShop?['id'];
    if (shopId == null) return;

    // 1. Validation
    for (var p in _variants) {
      final txt = _qtyControllers[p.id]?.text;
      if (txt != null && txt.isNotEmpty) {
        final qty = int.tryParse(txt) ?? 0;
        if (qty > p.quantity) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Stock insuffisant pour '${p.variant}': Max ${p.quantity}"), backgroundColor: Colors.red));
          return;
        }
      }
    }

    // 2. Envoi
    try {
      int count = 0;
      for (var p in _variants) {
        final qty = int.tryParse(_qtyControllers[p.id]?.text ?? '0') ?? 0;
        if (qty > 0) {
          await stock.recordSale(shopId, p.id, qty);
          count++;
        }
      }

      if (count > 0) {
        if (!mounted) return;
        WinkDialog.show(context, dialog: WinkDialog.success(
          title: "Vente Validée", 
          message: "Stock mis à jour.", 
          onPressed: () { Navigator.pop(context); Navigator.pop(context); }
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Aucune quantité saisie")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Sortie (Vente)"), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Recherche
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
              child: Autocomplete<String>(
                optionsBuilder: (v) {
                  if (v.text == '') return Provider.of<StockProvider>(context, listen: false).groupedProducts.keys;
                  return Provider.of<StockProvider>(context, listen: false).searchGrouped(v.text).keys;
                },
                onSelected: _onProductSelected,
                fieldViewBuilder: (context, controller, focusNode, onSubmitted) => TextField(
                  controller: controller, focusNode: focusNode,
                  decoration: const InputDecoration(
                    labelText: "Chercher un produit...", prefixIcon: Icon(Icons.search),
                    filled: true, fillColor: Colors.white, border: OutlineInputBorder()
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Liste Variantes
            if (_selectedProductName != null) ...[
              Text("Variantes pour '$_selectedProductName'", style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ..._variants.map((p) {
                bool empty = p.quantity <= 0;
                return Card(
                  color: empty ? Colors.grey.shade100 : Colors.white,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.variant ?? "Standard", style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text("Stock: ${p.quantity}  •  Prix: ${p.sellingPrice.toStringAsFixed(0)} F", style: TextStyle(color: empty ? Colors.red : Colors.grey)),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: _qtyControllers[p.id],
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: "0", contentPadding: const EdgeInsets.all(8),
                              border: const OutlineInputBorder(),
                              enabled: !empty
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              }).toList(),
              
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit, 
                style: ElevatedButton.styleFrom(backgroundColor: WinkTheme.success, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text("VALIDER LA VENTE"),
              )
            ]
          ],
        ),
      ),
    );
  }
}