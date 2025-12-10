// lib/screens/stock_journal_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:wink_merchant/providers/stock_provider.dart';
import 'package:wink_merchant/providers/auth_provider.dart';
import 'package:wink_merchant/utils/wink_theme.dart';
import 'package:wink_merchant/services/pdf_stock_service.dart'; // IMPORT DU SERVICE PDF

class StockJournalScreen extends StatefulWidget {
  const StockJournalScreen({super.key});

  @override
  State<StockJournalScreen> createState() => _StockJournalScreenState();
}

class _StockJournalScreenState extends State<StockJournalScreen> {
  // Filtres
  String _filterType = 'all'; 
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Période par défaut : 7 derniers jours
    final now = DateTime.now();
    _endDate = now;
    _startDate = now.subtract(const Duration(days: 7));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyFilters();
    });
  }

  void _applyFilters() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final shopId = auth.currentShop?['id'];
    if (shopId != null) {
      Provider.of<StockProvider>(context, listen: false).fetchJournal(
        shopId,
        type: _filterType,
        start: _startDate,
        end: _endDate,
        search: _searchController.text,
      );
    }
  }

  // --- FONCTION EXPORT PDF ---
  Future<void> _exportJournal() async {
    final stock = Provider.of<StockProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final shopName = auth.currentShop?['name'] ?? "Ma Boutique";

    if (stock.journal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Aucun mouvement à exporter.")));
      return;
    }

    try {
      // On utilise les données déjà chargées dans le provider (stock.journal)
      // et les dates sélectionnées
      await PdfStockService.generateJournalReport(
        shopName, 
        stock.journal, 
        _startDate ?? DateTime.now(), 
        _endDate ?? DateTime.now()
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur Export: $e"), backgroundColor: Colors.red));
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      locale: const Locale("fr", "FR"),
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 1)), 
      initialDateRange: _startDate != null && _endDate != null 
          ? DateTimeRange(start: _startDate!, end: _endDate!) 
          : null,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: WinkTheme.primary,
            colorScheme: ColorScheme.light(primary: WinkTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end.add(const Duration(hours: 23, minutes: 59, seconds: 59));
      });
      _applyFilters();
    }
  }

  @override
  Widget build(BuildContext context) {
    String dateLabel = "Sélectionner dates";
    if (_startDate != null && _endDate != null) {
      final fmt = DateFormat('dd MMM', 'fr_FR');
      dateLabel = "${fmt.format(_startDate!)} - ${fmt.format(_endDate!)}";
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Journal de Bord"),
        actions: [
          // BOUTON DATE
          TextButton.icon(
            onPressed: _selectDateRange,
            icon: const Icon(Icons.calendar_today, color: Colors.white, size: 16),
            label: Text(dateLabel, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ),
          // BOUTON EXPORT (NOUVEAU)
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: "Exporter le journal",
            onPressed: _exportJournal,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Rechercher...",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    suffixIcon: IconButton(icon: const Icon(Icons.refresh, color: Colors.blue), onPressed: _applyFilters)
                  ),
                  onSubmitted: (_) => _applyFilters(),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Tout', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Ventes', 'sale', Colors.red.shade100, Colors.red.shade900),
                      const SizedBox(width: 8),
                      _buildFilterChip('Entrées', 'entry', Colors.green.shade100, Colors.green.shade900),
                    ],
                  ),
                )
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Consumer<StockProvider>(
              builder: (context, stock, child) {
                if (stock.isLoading) return const Center(child: CircularProgressIndicator());
                if (stock.journal.isEmpty) {
                  return const Center(child: Text("Aucun mouvement sur cette période."));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: stock.journal.length,
                  itemBuilder: (ctx, i) => _buildJournalItem(stock.journal[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, [Color? bg, Color? text]) {
    final isSelected = _filterType == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: bg ?? Colors.blue.shade100,
      labelStyle: TextStyle(
        color: isSelected ? (text ?? Colors.blue.shade900) : Colors.black, 
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
      ),
      onSelected: (bool selected) {
        if (selected) {
          setState(() => _filterType = value);
          _applyFilters();
        }
      },
    );
  }

  Widget _buildJournalItem(Map<String, dynamic> item) {
    final type = item['type'];
    final quantity = item['quantity']; 
    final date = DateTime.tryParse(item['created_at']);
    final dateStr = date != null ? DateFormat('dd MMM à HH:mm', 'fr_FR').format(date) : '-';
    
    IconData icon;
    Color color;
    String prefix;

    switch (type) {
      case 'entry':
        icon = Icons.arrow_downward; 
        color = Colors.green;
        prefix = "+";
        break;
      case 'sale':
        icon = Icons.arrow_upward; 
        color = Colors.red;
        prefix = ""; 
        break;
      default:
        icon = Icons.sync_alt;
        color = Colors.grey;
        prefix = "";
    }

    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color, size: 20)),
        title: Text(item['product_name'] ?? 'Inconnu', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${item['variant_name'] ?? '-'} • $dateStr", style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
        trailing: Text("$prefix$quantity", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}