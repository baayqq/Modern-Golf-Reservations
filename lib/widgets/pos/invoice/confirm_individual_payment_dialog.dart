// Widget: Reusable dialog to confirm individual payment.
// Displays invoice info, amount, remaining after payment, payer, and method.

import 'package:flutter/material.dart';
import 'package:modern_golf_reservations/models/invoice_models.dart';
import 'package:modern_golf_reservations/utils/currency.dart';

class ConfirmIndividualPaymentDialog extends StatelessWidget {
  final InvoiceItem invoice;
  final double amount;
  final String payer;
  final String methodLabel;

  const ConfirmIndividualPaymentDialog({
    super.key,
    required this.invoice,
    required this.amount,
    required this.payer,
    required this.methodLabel,
  });

  static Future<bool> show(
    BuildContext context, {
    required InvoiceItem invoice,
    required double amount,
    required String payer,
    required String methodLabel,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => ConfirmIndividualPaymentDialog(
            invoice: invoice,
            amount: amount,
            payer: payer,
            methodLabel: methodLabel,
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final remaining = (invoice.outstanding - amount).clamp(0.0, double.infinity);
    return AlertDialog(
      title: const Text('Konfirmasi Pembayaran Individu'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Invoice: #${invoice.id}')
              ,
          Text('Customer: ${invoice.customer}'),
          const SizedBox(height: 8),
          Text('Nominal Bayar: ${Formatters.idr(amount)}'),
          Text('Sisa Tagihan Setelah Bayar: ${Formatters.idr(remaining)}'),
          const SizedBox(height: 8),
          Text('Pembayar: $payer'),
          Text('Metode: $methodLabel'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Bayar'),
        ),
      ],
    );
  }
}