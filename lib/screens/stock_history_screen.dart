// lib/screens/stock_history_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Pour formater la date
import 'package:wink_merchant/providers/auth_provider.dart';
import 'package:wink_merchant/services/api_service.dart';
import 'package:wink_merchant/utils/wink_theme.dart';

class StockHistoryScreen extends StatefulWidget {
  const StockHistoryScreen({super.key});

  @override
  State<StockHistoryScreen> createState() => _StockHistoryScreenState();
}

class _StockHistoryScreenState extends State<StockHistoryScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _historyItems = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final shopId = auth.currentShop?['id'];
      
      if (shopId == null) throw Exception("Boutique non identifiée");

      // Appel direct à l'API (Route créée précédemment)
      final response = await _apiService.client.get(
        '/stock/requests/my-history', 
        queryParameters: {'shop_id': shopId}
      );

      setState(() {
        _historyItems = response.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Impossible de charger l'historique.\nVérifiez votre connexion.";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WinkTheme.surface,
      appBar: AppBar(
        title: const Text("Suivi des Demandes"),
        actions: [
          IconButton(onPressed: _fetchHistory, icon: const Icon(Icons.refresh))
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            TextButton(onPressed: _fetchHistory, child: const Text("Réessayer"))
          ],
        ),
      );
    }

    if (_historyItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text("Aucune demande récente.", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _historyItems.length,
      itemBuilder: (context, index) {
        final item = _historyItems[index];
        return _buildHistoryCard(item);
      },
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item) {
    final status = item['status'] ?? 'pending';
    final date = DateTime.tryParse(item['created_at'] ?? '');
    final dateStr = date != null ? DateFormat('dd MMM à HH:mm').format(date) : '-';
    
    final productName = item['product_name'] ?? 'Produit inconnu';
    final variantName = item['variant_name'] ?? 'Standard';
    final qtyDeclared = item['quantity_declared'] ?? 0;
    
    // Détermination du style selon le statut
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'validated':
        statusColor = Colors.green;
        statusText = "VALIDÉ";
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = "REJETÉ";
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange;
        statusText = "EN ATTENTE";
        statusIcon = Icons.hourglass_top;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête : Date et Statut
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(dateStr, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.3))
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10)),
                    ],
                  ),
                )
              ],
            ),
            const Divider(height: 24),
            
            // Corps : Produit
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Center(child: Text(productName.substring(0,1).toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(variantName, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                // Quantité
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("Qté: $qtyDeclared", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    if (status == 'validated' && item['quantity_validated'] != null && item['quantity_validated'] != qtyDeclared)
                      Text("Reçu: ${item['quantity_validated']}", style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                )
              ],
            ),

            // Pied : Motif de rejet (si rejeté)
            if (status == 'rejected' && item['admin_comment'] != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  "Motif : ${item['admin_comment']}",
                  style: TextStyle(color: Colors.red.shade800, fontSize: 12, fontStyle: FontStyle.italic),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}