// lib/services/database_service.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'wink_merchant.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Table Produits (Miroir partiel du Backend)
    await db.execute('''
      CREATE TABLE products(
        local_id INTEGER PRIMARY KEY AUTOINCREMENT,
        id INTEGER UNIQUE, 
        shop_id INTEGER,
        reference TEXT,
        name TEXT,
        variant TEXT,
        quantity INTEGER,
        alert_threshold INTEGER,
        selling_price REAL,
        image_url TEXT,
        last_synced_at TEXT
      )
    ''');
  }

  // --- CRUD PRODUITS ---

  // Sauvegarde en masse (lors de la synchro)
  Future<void> batchInsertProducts(List<dynamic> productsList) async {
    final db = await database;
    final batch = db.batch();
    
    // On vide d'abord pour avoir un miroir exact
    batch.delete('products'); 

    for (var p in productsList) {
      // CORRECTION CRITIQUE : On ne garde que les champs qui existent dans la table locale
      // Sinon SQLite plante car il ne connait pas 'cost_price', 'created_at', etc.
      final Map<String, dynamic> cleanProduct = {
        'id': p['id'],
        'shop_id': p['shop_id'],
        'reference': p['reference'],
        'name': p['name'],
        'variant': p['variant'],
        'quantity': p['quantity'],
        'alert_threshold': p['alert_threshold'],
        'selling_price': p['selling_price'],
        'image_url': p['image_url'],
        'last_synced_at': DateTime.now().toIso8601String(),
      };

      batch.insert('products', cleanProduct, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getAllProducts() async {
    final db = await database;
    return await db.query('products', orderBy: 'name ASC');
  }
  
  // Méthode utilitaire si besoin d'insérer un seul produit manuellement
  Future<void> insertOrUpdateProduct(Map<String, dynamic> productJson) async {
    final db = await database;
    // Même nettoyage ici
    final Map<String, dynamic> cleanProduct = {
        'id': productJson['id'],
        'shop_id': productJson['shop_id'],
        'reference': productJson['reference'],
        'name': productJson['name'],
        'variant': productJson['variant'],
        'quantity': productJson['quantity'],
        'alert_threshold': productJson['alert_threshold'],
        'selling_price': productJson['selling_price'],
        'image_url': productJson['image_url'],
    };
    
    await db.insert(
      'products',
      cleanProduct,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}