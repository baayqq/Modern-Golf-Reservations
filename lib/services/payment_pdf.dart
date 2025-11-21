// Service: Generate printable PDF for a payment receipt.
// This builds a clean receipt with Payment ID, Payer, Date, Method,
// Amount, and a table of allocations to invoices. Designed for Flutter Web
// via the `printing` package.

import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../utils/currency.dart';

/// Simple data holder for payment allocation rows in the PDF.
class PaymentAllocation {
  final int invoiceId;
  final String customer;
  final num amount;
  final num invoiceTotal;
  final String status;

  const PaymentAllocation({
    required this.invoiceId,
    required this.customer,
    required this.amount,
    required this.invoiceTotal,
    required this.status,
  });
}

/// Generate a payment receipt PDF as bytes.
///
/// Layout:
/// - Title: "PAYMENT RECEIPT" bold size 24
/// - Meta: Payment ID, Date, Payer, Method, Amount
/// - Table: Invoice ID, Customer, Allocated Amount, Invoice Total, Status
Future<Uint8List> generatePaymentPdf({
  required int paymentId,
  required DateTime date,
  required String payer,
  required String method,
  required num amount,
  required List<PaymentAllocation> allocations,
}) async {
  final doc = pw.Document();

  final dateFmt = DateFormat('dd/MM/yyyy');
  final totalAllocated =
      allocations.fold<num>(0, (sum, a) => sum + (a.amount));

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
                'PAYMENT RECEIPT',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text('Payment ID: #$paymentId'),
              pw.Text('Tanggal: ${dateFmt.format(date)}'),
              pw.Text('Payer: $payer'),
              pw.Text('Metode: $method'),
              pw.Text('Jumlah Pembayaran: ${Formatters.idr(amount)}'),
              pw.SizedBox(height: 16),

              // Table of allocations
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.6),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1.5), // Invoice ID
                  1: const pw.FlexColumnWidth(3),   // Customer
                  2: const pw.FlexColumnWidth(2),   // Allocated Amount
                  3: const pw.FlexColumnWidth(2),   // Invoice Total
                  4: const pw.FlexColumnWidth(1.5), // Status
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _cell('Invoice ID', bold: true),
                      _cell('Customer', bold: true),
                      _cell('Allocated', bold: true),
                      _cell('Inv Total', bold: true),
                      _cell('Status', bold: true),
                    ],
                  ),
                  ...allocations.map(
                    (a) => pw.TableRow(
                      children: [
                        _cell('#${a.invoiceId}'),
                        _cell(a.customer),
                        _cell(Formatters.idr(a.amount)),
                        _cell(Formatters.idr(a.invoiceTotal)),
                        _cell(a.status.toUpperCase()),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 16),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Total Allocated: ${Formatters.idr(totalAllocated)}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                  pw.Text(
                    'Paid Amount: ${Formatters.idr(amount)}',
                    style: pw.TextStyle(
                      fontSize: 16,
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

// Helper to render a standard table cell.
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