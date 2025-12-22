import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../utils/currency.dart';

class InvoiceItem {
  final String productName;
  final int quantity;
  final num unitPrice;

  InvoiceItem({
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });

  num get subtotal => quantity * unitPrice;
}

Future<Uint8List> generateInvoicePdf({
  required DateTime invoiceDate,
  required String customerName,
  required List<InvoiceItem> items,
}) async {
  final doc = pw.Document();

  final dateFmt = DateFormat('dd/MM/yyyy');

  final total = items.fold<num>(0, (sum, item) => sum + item.subtotal);

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) {
        return pw.Padding(
          padding: const pw.EdgeInsets.all(24),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [

              pw.Text(
                'INVOICE',
                style: pw.TextStyle(
                  fontSize: 26,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),

              pw.Text('Tanggal: ${dateFmt.format(invoiceDate)}'),
              pw.Text('Customer: $customerName'),
              pw.SizedBox(height: 16),

              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.6),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _cell('Produk', bold: true),
                      _cell('Qty', bold: true),
                      _cell('Harga', bold: true),
                      _cell('Subtotal', bold: true),
                    ],
                  ),
                  ...items.map(
                    (item) => pw.TableRow(
                      children: [
                        _cell(item.productName),
                        _cell(item.quantity.toString()),
                        _cell(Formatters.idr(item.unitPrice)),
                        _cell(Formatters.idr(item.subtotal)),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 16),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    'Total: ${Formatters.idr(total)}',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );

  return doc.save();
}

pw.Widget _cell(String text, {bool bold = false}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
    child: pw.Align(
      alignment: pw.Alignment.centerLeft,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: 11,
        ),
      ),
    ),
  );
}