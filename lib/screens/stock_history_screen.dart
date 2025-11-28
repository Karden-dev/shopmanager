import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Pour formater les dates
import 'package:wink_merchant/providers/stock_provider.dart';
import 'package:wink_merchant/providers/auth_provider.dart';
import 'package:wink_merchant/utils/wink_theme.dart';

class StockHistoryScreen extends StatefulWidget {
  const StockHistoryScreen({super.key});

  @override
  State<StockHistoryScreen> createState() => _StockHistoryScreenState();
}

class _StockHistoryScreenState extends State<StockHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filterType = 'all'; // all, sale, entry
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchHistory());
  }

  void _fetchHistory() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final stock = Provider.of<StockProvider>(context, listen: false);
    final shopId = auth.currentShop?['id'];
    
    if (shopId != null) {
      String? startStr;
      String? endStr;
      
      if (_selectedDateRange != null) {
        startStr = DateFormat('yyyy-MM-dd').format(_selectedDateRange!.start);
        endStr = DateFormat('yyyy-MM-dd').format(_selectedDateRange!.end);
      }

      stock.loadGlobalHistory(
        shopId,
        search: _searchController.text.isEmpty ? null : _searchController.text,
        type: _filterType == 'all' ? null : _filterType,
        startDate: startStr,
        endDate: endStr,
      );
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );
    if (picked != null) {
      setState(() => _selectedDateRange = picked);
      _fetchHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text("Journal des Mouvements", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_off),
            tooltip: "Réinitialiser filtres",
            onPressed: () {
              setState(() {
                _filterType = 'all';
                _searchController.clear();
                _selectedDateRange = null;
              });
              _fetchHistory();
            },
          )
        ],
      ),
      body: Column(
        children: [
          // --- BARRE DE FILTRES ---
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Column(
              children: [
                // Recherche
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Rechercher (Produit)...",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: const Color(0xFFF4F6F8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (_) => _fetchHistory(),
                ),
                const SizedBox(height: 12),
                
                // Filtres (Date & Type)
                Row(
                  children: [
                    // Date Picker
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDateRange,
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          _selectedDateRange == null 
                            ? "Toutes les dates" 
                            : "${DateFormat('dd/MM').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM').format(_selectedDateRange!.end)}",
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Type Dropdown
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _filterType,
                            isExpanded: true,
                            style: const TextStyle(fontSize: 13, color: Colors.black87),
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text("Tous types")),
                              DropdownMenuItem(value: 'sale', child: Text("Ventes")),
                              DropdownMenuItem(value: 'entry', child: Text("Entrées")),
                              DropdownMenuItem(value: 'adjustment', child: Text("Ajustements")),
                            ],
                            onChanged: (val) {
                              setState(() => _filterType = val!);
                              _fetchHistory();
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // --- LISTE DES MOUVEMENTS ---
          Expanded(
            child: Consumer<StockProvider>(
              builder: (context, stock, _) {
                if (stock.isLoading) return const Center(child: CircularProgressIndicator());
                if (stock.globalHistory.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 60, color: Colors.grey),
                        SizedBox(height: 10),
                        Text("Aucun mouvement trouvé", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: stock.globalHistory.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                  itemBuilder: (ctx, index) {
                    final move = stock.globalHistory[index];
                    return _buildMovementCard(move);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovementCard(dynamic move) {
    final type = move['type'] ?? 'unknown';
    final quantity = int.tryParse(move['quantity'].toString()) ?? 0;
    final isEntry = quantity > 0; // En général, >0 pour entrée, <0 pour sortie
    // Si votre backend stocke les ventes en négatif, sinon ajustez la logique
    
    // Déterminer le style
    IconData icon;
    Color color;
    String label;

    if (type == 'sale') {
      icon = Icons.arrow_upward;
      color = WinkTheme.error; // Rouge
      label = "Vente";
    } else if (type == 'entry') {
      icon = Icons.arrow_downward;
      color = WinkTheme.success; // Vert
      label = "Entrée";
    } else {
      icon = Icons.refresh;
      color = Colors.blue;
      label = "Ajustement";
    }

    // Date
    final date = DateTime.tryParse(move['created_at'] ?? '') ?? DateTime.now();
    final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(date);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          move['product_name'] ?? 'Produit Inconnu',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (move['variant'] != null)
              Text("Variante: ${move['variant']}", style: const TextStyle(fontSize: 12, color: Colors.black87)),
            const SizedBox(height: 4),
            Text(dateStr, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "${quantity > 0 ? '+' : ''}$quantity",
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: color),
            ),
            Text(label, style: TextStyle(fontSize: 10, color: color)),
          ],
        ),
      ),
    );
  }
}