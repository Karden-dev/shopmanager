// lib/screens/stock_entry_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wink_merchant/providers/stock_provider.dart';
import 'package:wink_merchant/providers/auth_provider.dart';
import 'package:wink_merchant/models/product.dart';
import 'package:wink_merchant/utils/wink_theme.dart';
import 'package:wink_merchant/widgets/common/wink_dialog.dart';

class StockEntryScreen extends StatefulWidget {
  const StockEntryScreen({super.key});

  @override
  State<StockEntryScreen> createState() => _StockEntryScreenState();
}

class _StockEntryScreenState extends State<StockEntryScreen> {
  // État de la sélection
  String? _selectedProductName;
  List<Product> _existingVariants = [];
  
  // Contrôleurs (Map: ID Produit -> Controller)
  final Map<int, TextEditingController> _qtyControllers = {};
  
  // Nouvelles variantes (volatiles)
  final List<Map<String, dynamic>> _newVariantsToAdd = []; 

  File? _proofImage;
  bool _isCompressing = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Charger le catalogue au démarrage pour l'autocomplete
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

  // --- LOGIQUE MÉTIER ---

  void _onProductSelected(String productName) {
    setState(() {
      _selectedProductName = productName;
      _qtyControllers.clear();
      _newVariantsToAdd.clear();
      
      final stock = Provider.of<StockProvider>(context, listen: false);
      _existingVariants = stock.groupedProducts[productName] ?? [];
      
      for (var p in _existingVariants) {
        _qtyControllers[p.id] = TextEditingController();
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await ImagePicker().pickImage(source: source, maxWidth: 1200);
      if (pickedFile != null) {
        setState(() => _isCompressing = true);
        final File? compressed = await _compressImage(File(pickedFile.path));
        setState(() { _proofImage = compressed; _isCompressing = false; });
      }
    } catch (e) {
      setState(() => _isCompressing = false);
    }
  }

  Future<File?> _compressImage(File file) async {
    final tempDir = await getTemporaryDirectory();
    final targetPath = "${tempDir.path}/proof_${DateTime.now().millisecondsSinceEpoch}.jpg";
    var result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path, targetPath, quality: 75, minWidth: 1024
    );
    return result != null ? File(result.path) : null;
  }

  void _addNewVariantDialog() {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Ajouter une variante"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Nom (ex: XXL, Jaune)", border: OutlineInputBorder()),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: qtyCtrl,
              decoration: const InputDecoration(labelText: "Quantité reçue", border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && qtyCtrl.text.isNotEmpty) {
                setState(() {
                  _newVariantsToAdd.add({
                    'variant': nameCtrl.text.trim(),
                    'qty': qtyCtrl.text.trim(),
                    'controller': TextEditingController(text: qtyCtrl.text.trim())
                  });
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text("Ajouter"),
          )
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_proofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("📸 Photo de preuve obligatoire"), backgroundColor: Colors.red));
      return;
    }

    if (_qtyControllers.values.every((c) => c.text.isEmpty || c.text == "0") && _newVariantsToAdd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Aucune quantité saisie"), backgroundColor: Colors.orange));
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final stock = Provider.of<StockProvider>(context, listen: false);
    final shopId = auth.currentShop?['id'];

    if (shopId == null) return;

    try {
      int count = 0;

      // 1. Variantes existantes
      for (var entry in _qtyControllers.entries) {
        final qty = int.tryParse(entry.value.text) ?? 0;
        if (qty > 0) {
          await stock.declareEntry(
            {'shop_id': shopId, 'product_id': entry.key, 'quantity': qty},
            proofFile: _proofImage
          );
          count++;
        }
      }

      // 2. Nouvelles variantes (Création + Entrée)
      for (var newVar in _newVariantsToAdd) {
         final baseProduct = _existingVariants.isNotEmpty ? _existingVariants.first : null;
         
         final newProd = await stock.createProduct({
           'shop_id': shopId,
           'name': _selectedProductName,
           'variant': newVar['variant'],
           'selling_price': baseProduct?.sellingPrice ?? 0,
           'alert_threshold': 5,
         });

         await stock.declareEntry(
            {'shop_id': shopId, 'product_id': newProd.id, 'quantity': int.parse(newVar['qty'])},
            proofFile: _proofImage
         );
         count++;
      }

      if (mounted) {
        WinkDialog.show(context, dialog: WinkDialog.success(
          title: "Envoyé !",
          message: "$count entrées transmises pour validation.",
          onPressed: () => Navigator.pop(context),
        ));
      }

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red));
    }
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Fond très léger
      appBar: AppBar(
        title: const Text("Nouvel Arrivage"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. RECHERCHE PRODUIT (Carte Blanche)
            _buildSectionCard(
              title: "Quel produit avez-vous reçu ?",
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
                      hintText: "Nom du produit (ex: Savon)...",
                      prefixIcon: const Icon(Icons.search, color: WinkTheme.primary),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // 2. LISTE DES VARIANTES (S'affiche si produit sélectionné)
            if (_selectedProductName != null) ...[
              _buildSectionCard(
                title: "Variantes de '$_selectedProductName'",
                child: Column(
                  children: [
                    // Variantes Existantes
                    ..._existingVariants.map((p) => _buildVariantRow(p)),
                    
                    // Nouvelles Variantes
                    ..._newVariantsToAdd.map((v) => _buildNewVariantRow(v)),

                    const SizedBox(height: 16),
                    // Bouton Ajout
                    OutlinedButton.icon(
                      onPressed: _addNewVariantDialog,
                      icon: const Icon(Icons.add),
                      label: const Text("Créer une nouvelle variante"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // 3. PREUVE (Zone Photo)
            _buildSectionCard(
              title: "Preuve de réception",
              child: GestureDetector(
                onTap: () => _showImageSourceModal(context),
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _proofImage != null ? WinkTheme.primary : Colors.grey.shade400, width: 2, style: BorderStyle.solid), // Pointillés simulés par couleur grise
                    image: _proofImage != null 
                      ? DecorationImage(image: FileImage(_proofImage!), fit: BoxFit.cover) 
                      : null,
                  ),
                  child: _proofImage == null 
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_rounded, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text("Toucher pour prendre une photo\n(Bordereau ou Colis)", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
                        ],
                      )
                    : Container(
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.all(8),
                        child: CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.edit, color: WinkTheme.primary)),
                      ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // 4. BOUTON VALIDATION
            Consumer<StockProvider>(
              builder: (ctx, stock, _) {
                return SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: (stock.isLoading || _isCompressing) ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: WinkTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: (stock.isLoading || _isCompressing)
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("VALIDER L'ENTRÉE", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                );
              }
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS HELPERS ---

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

  Widget _buildVariantRow(Product p) {
    final controller = _qtyControllers[p.id];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          // Info Variante
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.variant ?? "Standard", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text("Stock actuel: ${p.quantity}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          // Input Qté
          Container(
            width: 100,
            decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              decoration: const InputDecoration(
                hintText: "0",
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewVariantRow(Map<String, dynamic> v) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("${v['variant']} (Nouveau)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800)),
              const Text("Création automatique", style: TextStyle(fontSize: 10, color: Colors.green)),
            ],
          ),
          Text("+ ${v['qty']}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green.shade900)),
        ],
      ),
    );
  }

  void _showImageSourceModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Wrap(
            children: [
              ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.camera_alt, color: Colors.white)),
                title: const Text('Prendre une photo'),
                onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
              ),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.purple, child: Icon(Icons.photo_library, color: Colors.white)),
                title: const Text('Choisir dans la galerie'),
                onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
              ),
            ],
          ),
        ),
      ),
    );
  }
}