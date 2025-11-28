import 'dart:io';
import 'dart:convert';
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
  final _formKey = GlobalKey<FormState>();
  
  // État de la sélection
  String? _selectedProductName;
  List<Product> _existingVariants = [];
  
  // Contrôleurs pour les quantités (Map: ID Produit -> Controller)
  final Map<int, TextEditingController> _qtyControllers = {};
  
  // Gestion des NOUVELLES variantes à créer à la volée
  final List<Map<String, dynamic>> _newVariantsToAdd = []; // {variant: String, qty: String}

  File? _proofImage;
  bool _isCompressing = false;

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
    // Nettoyage des contrôleurs
    for (var c in _qtyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // --- LOGIQUE DE SÉLECTION ---

  void _onProductSelected(String productName) {
    setState(() {
      _selectedProductName = productName;
      _qtyControllers.clear();
      _newVariantsToAdd.clear();
      
      // Récupérer les variantes existantes depuis le Provider
      final stock = Provider.of<StockProvider>(context, listen: false);
      _existingVariants = stock.groupedProducts[productName] ?? [];
      
      // Initialiser un contrôleur pour chaque variante existante
      for (var p in _existingVariants) {
        _qtyControllers[p.id] = TextEditingController();
      }
    });
  }

  void _addNewVariantField() {
    // Ouvre une petite boîte de dialogue pour saisir le nom de la nouvelle variante
    final variantNameController = TextEditingController();
    final qtyController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Nouvelle Variante"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: variantNameController,
              decoration: const InputDecoration(labelText: "Nom (ex: Vert, XL)"),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: qtyController,
              decoration: const InputDecoration(labelText: "Quantité reçue"),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () {
              if (variantNameController.text.isNotEmpty && qtyController.text.isNotEmpty) {
                setState(() {
                  _newVariantsToAdd.add({
                    'variant': variantNameController.text.trim(),
                    'qty': qtyController.text.trim(),
                    'controller': TextEditingController(text: qtyController.text.trim()) // Pour affichage liste
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

  // --- GESTION IMAGE ---
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await ImagePicker().pickImage(source: source, maxWidth: 1024);
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
    var result = await FlutterImageCompress.compressAndGetFile(file.absolute.path, targetPath, quality: 60, minWidth: 800);
    return result != null ? File(result.path) : null;
  }

  // --- SOUMISSION ---
  Future<void> _submit() async {
    if (_proofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Photo preuve requise")));
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final stock = Provider.of<StockProvider>(context, listen: false);
    final shopId = auth.currentShop?['id'];

    // Préparer l'image
    List<int> imageBytes = await _proofImage!.readAsBytes();
    String base64Image = "data:image/jpeg;base64,${base64Encode(imageBytes)}";

    try {
      int operationsCount = 0;

      // 1. Traiter les variantes EXISTANTES
      for (var entry in _qtyControllers.entries) {
        final productId = entry.key;
        final qtyText = entry.value.text;
        if (qtyText.isNotEmpty && int.parse(qtyText) > 0) {
          await stock.declareEntry({
            'shop_id': shopId,
            'product_id': productId,
            'quantity': int.parse(qtyText),
            'proof_url': base64Image,
          });
          operationsCount++;
        }
      }

      // 2. Traiter les NOUVELLES variantes (Création + Entrée)
      // Note: Pour simplifier, on suppose ici qu'on crée le produit. 
      // Idéalement le backend devrait avoir une route "create_and_stock", mais on fait en 2 temps.
      for (var newVar in _newVariantsToAdd) {
         // On clone les infos du premier produit existant pour garder le même prix/seuil
         // Ou on met des défauts si c'est une création pure (cas rare ici car on part d'un nom existant)
         final baseProduct = _existingVariants.isNotEmpty ? _existingVariants.first : null;
         
         // Création
         final newProduct = await stock.createProduct({ // Nouvelle méthode dans Provider (voir plus bas)
           'shop_id': shopId,
           'name': _selectedProductName,
           'variant': newVar['variant'],
           'selling_price': baseProduct?.sellingPrice ?? 0,
           'alert_threshold': baseProduct?.alertThreshold ?? 5,
           // Pas d'image produit spécifique ici, on garde simple
         });

         // Déclaration Stock
         await stock.declareEntry({
            'shop_id': shopId,
            'product_id': newProduct.id, // L'ID qui vient d'être créé
            'quantity': int.parse(newVar['qty']),
            'proof_url': base64Image,
         });
         operationsCount++;
      }

      if (operationsCount > 0) {
         if (!mounted) return;
         WinkDialog.show(context, dialog: WinkDialog.success(
           title: "Succès",
           message: "$operationsCount lignes de stock envoyées pour validation.",
           onPressed: () => Navigator.pop(context), // Retour
         ));
      } else {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Aucune quantité saisie.")));
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WinkTheme.surface,
      appBar: AppBar(title: const Text("Entrée Multi-Variantes")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. RECHERCHE PAR NOM
            const Text("Produit Concerné", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text == '') {
                   // Retourne tous les noms de produits uniques
                   return Provider.of<StockProvider>(context, listen: false).groupedProducts.keys;
                }
                return Provider.of<StockProvider>(context, listen: false)
                    .searchGrouped(textEditingValue.text).keys;
              },
              onSelected: _onProductSelected,
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: "Tapez le nom du produit (ex: Jardin)",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: WinkTheme.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // 2. LISTE DES VARIANTES (Si produit sélectionné)
            if (_selectedProductName != null) ...[
              Text("Variantes de '$_selectedProductName'", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: WinkTheme.primary)),
              const SizedBox(height: 10),
              
              // Liste existante
              ..._existingVariants.map((product) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 0,
                  color: WinkTheme.background,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(product.variant ?? "Standard", style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text("Stock actuel : ${product.quantity}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          child: TextField(
                            controller: _qtyControllers[product.id],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              hintText: "0",
                              contentPadding: EdgeInsets.symmetric(vertical: 8),
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),

              // Liste des nouvelles variantes ajoutées à la volée
               ..._newVariantsToAdd.map((newVar) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: Colors.green.shade50, // Distinction visuelle
                  child: ListTile(
                    title: Text("${newVar['variant']} (Nouveau)", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    trailing: Text("+ ${newVar['qty']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                );
              }).toList(),

              // Bouton Ajout Variante
              Center(
                child: TextButton.icon(
                  onPressed: _addNewVariantField,
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text("Ajouter une variante qui n'existe pas"),
                ),
              ),
              
              const Divider(height: 30),

              // 3. PREUVE
              const Text("Preuve (Photo)", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _pickImage(ImageSource.camera),
                child: Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                    image: _proofImage != null ? DecorationImage(image: FileImage(_proofImage!), fit: BoxFit.cover) : null
                  ),
                  child: _proofImage == null ? const Center(child: Icon(Icons.camera_alt, color: Colors.grey)) : null,
                ),
              ),
              
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isCompressing ? null : _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: WinkTheme.primary, foregroundColor: Colors.white),
                  child: _isCompressing ? const CircularProgressIndicator(color: Colors.white) : const Text("VALIDER TOUTES LES ENTRÉES"),
                ),
              )
            ],
          ],
        ),
      ),
    );
  }
}