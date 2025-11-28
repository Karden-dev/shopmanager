// lib/screens/stock_create_screen.dart

import 'dart:io';
import 'dart:convert'; // Pour convertir l'image en Base64
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wink_merchant/providers/stock_provider.dart';
import 'package:wink_merchant/providers/auth_provider.dart';
import 'package:wink_merchant/utils/wink_theme.dart';
import 'package:wink_merchant/widgets/common/wink_dialog.dart'; // Notre belle modale

class StockCreateScreen extends StatefulWidget {
  const StockCreateScreen({super.key});

  @override
  State<StockCreateScreen> createState() => _StockCreateScreenState();
}

class _StockCreateScreenState extends State<StockCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Contrôleurs de texte
  final _nameController = TextEditingController();
  final _variantController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _alertThresholdController = TextEditingController(text: '5'); // Valeur par défaut

  // Gestion Image
  File? _imageFile;
  bool _isCompressing = false;

  @override
  void dispose() {
    _nameController.dispose();
    _variantController.dispose();
    _sellingPriceController.dispose();
    _alertThresholdController.dispose();
    super.dispose();
  }

  // --- LOGIQUE IMAGE ---

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1024, // On limite la taille brute dès la prise
      );

      if (pickedFile != null) {
        setState(() => _isCompressing = true);
        
        // Compression
        final File originalFile = File(pickedFile.path);
        final File? compressedFile = await _compressImage(originalFile);

        setState(() {
          _imageFile = compressedFile;
          _isCompressing = false;
        });
      }
    } catch (e) {
      setState(() => _isCompressing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur photo: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<File?> _compressImage(File file) async {
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    final targetPath = "$path/prod_${DateTime.now().millisecondsSinceEpoch}.jpg";

    // Compression forte (qualité 70%) pour ne pas surcharger le serveur
    var result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 70, 
      minWidth: 800,
      minHeight: 800,
    );

    if (result == null) return null;
    return File(result.path);
  }

  // --- LOGIQUE SOUMISSION ---

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final stock = Provider.of<StockProvider>(context, listen: false);
    
    // Récupération sécurisée du Shop ID (via la persistance qu'on a ajoutée)
    final shopId = auth.currentShop?['id'];
    final shopName = auth.currentShop?['name'];
    
    if (shopId == null) {
      WinkDialog.show(
        context, 
        dialog: WinkDialog.alert(
          title: "Erreur Session", 
          message: "Impossible d'identifier votre boutique. Veuillez vous reconnecter.", 
          onPressed: () => Navigator.pop(context)
        )
      );
      return;
    }

    // Encodage de l'image en Base64 (si présente)
    String? base64Image;
    if (_imageFile != null) {
      List<int> imageBytes = await _imageFile!.readAsBytes();
      base64Image = "data:image/jpeg;base64,${base64Encode(imageBytes)}";
    }

    // Préparation des données (Pas de référence ici, le backend s'en charge)
    final productData = {
      'shop_id': shopId,
      'shop_name': shopName, 
      'name': _nameController.text.trim(),
      'variant': _variantController.text.trim(),
      'selling_price': double.tryParse(_sellingPriceController.text) ?? 0,
      'alert_threshold': int.tryParse(_alertThresholdController.text) ?? 5,
      'image_url': base64Image, // Peut être null
      // 'cost_price': ... (Masqué pour l'instant)
    };

    try {
      await stock.addProduct(productData);
      
      if (!mounted) return;
      
      // Succès
      WinkDialog.show(
        context, 
        dialog: WinkDialog.success(
          title: "Produit Ajouté !", 
          message: "L'article a été ajouté à votre catalogue.", 
          onPressed: () {
            Navigator.pop(context); // Ferme Dialog
            Navigator.pop(context); // Retour Liste
            
            // Recharger la liste pour voir le nouveau produit
            stock.loadProducts(shopId);
          }
        )
      );

    } catch (e) {
      if (!mounted) return;
      WinkDialog.show(
        context, 
        dialog: WinkDialog.alert(
          title: "Erreur", 
          message: e.toString().replaceAll("Exception:", ""), 
          onPressed: () => Navigator.pop(context)
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Nouveau Produit"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- 1. ZONE IMAGE ---
              Center(
                child: GestureDetector(
                  onTap: () => _showImageSourceModal(context),
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                      image: _imageFile != null 
                        ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                        : null,
                    ),
                    child: _isCompressing 
                        ? const Center(child: CircularProgressIndicator())
                        : (_imageFile == null 
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo_rounded, size: 32, color: WinkTheme.primary.withOpacity(0.5)),
                                  const SizedBox(height: 8),
                                  Text("Ajouter Photo", style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                                ],
                              )
                            : null),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(child: Text("(Optionnel)", style: TextStyle(color: Colors.grey, fontSize: 12))),
              
              const SizedBox(height: 32),

              // --- 2. FORMULAIRE ---
              
              // Nom
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nom du Produit *',
                  hintText: 'Ex: Savon Noir, Robe...',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Le nom est obligatoire' : null,
              ),
              const SizedBox(height: 20),

              // Variante & Seuil (Ligne 2)
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _variantController,
                      decoration: const InputDecoration(
                        labelText: 'Variante',
                        hintText: 'Ex: Rouge, XL',
                        prefixIcon: Icon(Icons.style_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _alertThresholdController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Alerte',
                        hintText: 'Min',
                        prefixIcon: Icon(Icons.notifications_none),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Prix de Vente
              TextFormField(
                controller: _sellingPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Prix de Vente',
                  prefixIcon: Icon(Icons.attach_money),
                  suffixText: 'FCFA',
                ),
              ),
              
              const SizedBox(height: 40),

              // --- 3. BOUTON D'ACTION ---
              Consumer<StockProvider>(
                builder: (context, stock, _) {
                  return SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: stock.isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: WinkTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: stock.isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("ENREGISTRER LE PRODUIT", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Modale choix photo (Caméra / Galerie)
  void _showImageSourceModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Wrap(
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt, color: Colors.blue),
                ),
                title: const Text('Prendre une photo', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.purple.shade50, shape: BoxShape.circle),
                  child: const Icon(Icons.photo_library, color: Colors.purple),
                ),
                title: const Text('Choisir dans la galerie', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}