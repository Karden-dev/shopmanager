// lib/services/pdf_stock_service.dart

import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PdfStockService {
  
  static const PdfColor primaryColor = PdfColor.fromInt(0xFFFF9900);
  static const PdfColor tableHeaderColor = PdfColor.fromInt(0xFF333333);
  static const PdfColor zebraColor = PdfColor.fromInt(0xFFF9F9F9);

  // --- UTILITAIRE DE SÉCURITÉ ---
  // Convertit n'importe quoi (String, null, double) en int propre
  static int _safeInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  /// --- RAPPORT 1 : ÉTAT DE STOCK GLOBAL (INVENTAIRE) ---
  static Future<void> generateInventoryReport(String shopName, List<dynamic> data) async {
    final pdf = pw.Document();
    
    // Polices (Si erreur de chargement, utilisez pw.Font.courier() pour tester)
    final font = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();
    
    final dateStr = DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now());

    // Calcul des totaux sécurisé
    int grandTotalEntries = 0;
    int grandTotalExits = 0;
    int grandTotalStock = 0;

    for (var item in data) {
      grandTotalEntries += _safeInt(item['entries']);
      grandTotalExits += _safeInt(item['exits']);
      grandTotalStock += _safeInt(item['final_stock']);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (pw.Context context) {
          return [
            // HEADER
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(shopName.toUpperCase(), style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                      pw.Text("RAPPORT D'INVENTAIRE", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
                      pw.Text("Bilan des flux depuis le début", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                    ],
                  ),
                  pw.Text("Généré le $dateStr", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                ]
              )
            ),
            pw.SizedBox(height: 20),

            // TABLEAU
            pw.Table.fromTextArray(
              context: context,
              border: null,
              headerDecoration: const pw.BoxDecoration(color: tableHeaderColor),
              headerStyle: pw.TextStyle(color: PdfColors.white, fontSize: 9, fontWeight: pw.FontWeight.bold),
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5))),
              oddRowDecoration: const pw.BoxDecoration(color: zebraColor),
              cellPadding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerRight,
                5: pw.Alignment.centerRight,
              },
              headers: ["ARTICLE", "RÉF", "INITIAL", "ENTRÉES", "SORTIES", "FINAL"],
              data: data.map((item) {
                String fullName = item['name'] ?? 'Inconnu';
                if (item['variant'] != null && item['variant'].toString().isNotEmpty) {
                  fullName += " (${item['variant']})";
                }

                // Utilisation de _safeInt pour l'affichage aussi
                return [
                  fullName,
                  item['reference'] ?? '-',
                  _safeInt(item['initial_stock']).toString(),
                  "${_safeInt(item['entries'])}",
                  "${_safeInt(item['exits'])}",
                  _safeInt(item['final_stock']).toString(),
                ];
              }).toList(),
            ),

            // RÉSUMÉ
            pw.SizedBox(height: 25),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  width: 240,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: PdfColors.grey300)
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text("SYNTHÈSE DES MOUVEMENTS", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.grey700)),
                      pw.Divider(color: PdfColors.grey400),
                      _buildSummaryRow("Total Entrées", "$grandTotalEntries"),
                      _buildSummaryRow("Total Sorties", "$grandTotalExits"),
                      pw.Divider(color: PdfColors.grey400),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text("STOCK FINAL", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                          pw.Text("$grandTotalStock", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                        ]
                      )
                    ]
                  )
                )
              ]
            ),
            
            // FOOTER
            pw.Spacer(),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text("Document généré par WINK Manager", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Inventaire_${shopName.replaceAll(" ", "_")}_$dateStr',
    );
  }

  /// --- RAPPORT 2 : JOURNAL DES MOUVEMENTS (HISTORIQUE) ---
  static Future<void> generateJournalReport(String shopName, List<dynamic> journalData, DateTime start, DateTime end) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();
    
    final periodStr = "${DateFormat('dd/MM/yyyy').format(start)} au ${DateFormat('dd/MM/yyyy').format(end)}";

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(shopName.toUpperCase(), style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                      pw.Text("JOURNAL DES MOUVEMENTS", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      pw.Text("Période : $periodStr", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Text(DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()), style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                ]
              )
            ),
            pw.SizedBox(height: 20),

            pw.Table.fromTextArray(
              context: context,
              border: null,
              headerDecoration: const pw.BoxDecoration(color: tableHeaderColor),
              headerStyle: pw.TextStyle(color: PdfColors.white, fontSize: 9, fontWeight: pw.FontWeight.bold),
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5))),
              oddRowDecoration: const pw.BoxDecoration(color: zebraColor),
              headers: ["DATE", "ARTICLE", "TYPE", "QTÉ"],
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerRight,
              },
              data: journalData.map((item) {
                final date = DateTime.tryParse(item['created_at'] ?? '');
                final dateFmt = date != null ? DateFormat('dd/MM HH:mm').format(date) : '-';
                
                String fullName = item['product_name'] ?? 'Inconnu';
                if (item['variant_name'] != null) fullName += " (${item['variant_name']})";

                String typeLabel = item['type'].toString().toUpperCase();
                if (typeLabel == 'SALE') typeLabel = "VENTE";
                if (typeLabel == 'ENTRY') typeLabel = "ENTRÉE";

                // Sécurisation de la quantité
                int q = _safeInt(item['quantity']);
                String qtyStr = "$q";
                if (item['type'] == 'entry') qtyStr = "+$q";

                return [dateFmt, fullName, typeLabel, qtyStr];
              }).toList(),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Journal_${shopName}_${DateFormat('yyyyMMdd').format(start)}',
    );
  }

  static pw.Widget _buildSummaryRow(String label, String value, {bool isBold = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 10, fontWeight: isBold ? pw.FontWeight.bold : null)),
          pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: isBold ? pw.FontWeight.bold : null, color: color)),
        ]
      )
    );
  }
}