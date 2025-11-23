// Widget: Dialog to prompt printing/downloading a saved combined payment receipt.
// Converts generic PaymentAllocationData to paypdf.PaymentAllocation for PDF.

import 'package:flutter/material.dart';
import 'package:modern_golf_reservations/models/invoice_models.dart';
import 'package:modern_golf_reservations/services/payment_pdf.dart' as paypdf;
import 'package:printing/printing.dart';
import 'package:modern_golf_reservations/utils/currency.dart';

class PrintSavedCombinedPaymentDialog extends StatelessWidget {
  final int paymentId;
  final String payer;
  final String methodLabel;
  final num total;
  final List<PaymentAllocationData> allocations;

  const PrintSavedCombinedPaymentDialog({
    super.key,
    required this.paymentId,
    required this.payer,
    required this.methodLabel,
    required this.total,
    required this.allocations,
  });

  static Future<void> show(
    BuildContext context, {
    required int paymentId,
    required String payer,
    required String methodLabel,
    required num total,
    required List<PaymentAllocationData> allocations,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => PrintSavedCombinedPaymentDialog(
        paymentId: paymentId,
        payer: payer,
        methodLabel: methodLabel,
        total: total,
        allocations: allocations,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Kwitansi Pembayaran Gabungan'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment ID: #$paymentId'),
          Text('Pembayar: $payer'),
          Text('Metode: $methodLabel'),
          const SizedBox(height: 8),
          Text(
            'Total: ${Formatters.idr(total)}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text('Ingin mencetak atau mengunduh kwitansi sekarang?'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Nanti'),
        ),
        OutlinedButton(
          onPressed: () async {
            Navigator.of(context).pop();
            try {
              final pdfAlloc = allocations
                  .map((a) => paypdf.PaymentAllocation(
                        invoiceId: a.invoiceId,
                        customer: a.customer,
                        amount: a.amount,
                        invoiceTotal: a.invoiceTotal,
                        status: a.status,
                      ))
                  .toList();
              final bytes = await paypdf.generatePaymentPdf(
                paymentId: paymentId,
                date: DateTime.now(),
                payer: payer,
                method: methodLabel,
                amount: total,
                allocations: pdfAlloc,
              );
              await Printing.sharePdf(bytes: bytes, filename: 'payment_$paymentId.pdf');
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Gagal mengunduh PDF: $e')),
              );
            }
          },
          child: const Text('Download'),
        ),
        FilledButton(
          onPressed: () async {
            Navigator.of(context).pop();
            try {
              final pdfAlloc = allocations
                  .map((a) => paypdf.PaymentAllocation(
                        invoiceId: a.invoiceId,
                        customer: a.customer,
                        amount: a.amount,
                        invoiceTotal: a.invoiceTotal,
                        status: a.status,
                      ))
                  .toList();
              await Printing.layoutPdf(
                onLayout: (format) => paypdf.generatePaymentPdf(
                  paymentId: paymentId,
                  date: DateTime.now(),
                  payer: payer,
                  method: methodLabel,
                  amount: total,
                  allocations: pdfAlloc,
                ),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Gagal membuka dialog print: $e')),
              );
            }
          },
          child: const Text('Print'),
        ),
      ],
    );
  }
}