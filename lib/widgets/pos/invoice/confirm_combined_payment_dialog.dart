import 'package:flutter/material.dart';
import 'package:modern_golf_reservations/models/invoice_models.dart';
import 'package:modern_golf_reservations/utils/currency.dart';

class ConfirmCombinedPaymentDialog extends StatelessWidget {
  final String payer;
  final String methodLabel;
  final List<PaymentAllocationData> allocations;

  const ConfirmCombinedPaymentDialog({
    super.key,
    required this.payer,
    required this.methodLabel,
    required this.allocations,
  });

  static Future<bool> show(
    BuildContext context, {
    required String payer,
    required String methodLabel,
    required List<PaymentAllocationData> allocations,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => ConfirmCombinedPaymentDialog(
            payer: payer,
            methodLabel: methodLabel,
            allocations: allocations,
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final total = allocations.fold<num>(0, (s, e) => s + e.amount);
    return AlertDialog(
      title: const Text('Konfirmasi Pembayaran Gabungan'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Jumlah invoice: ${allocations.length}')
                ,
            Text('Pembayar: $payer'),
            Text('Metode: $methodLabel'),
            const SizedBox(height: 8),
            const Text('Rincian Alokasi:'),
            const SizedBox(height: 4),
            ...allocations.map((a) => Text(
                  '#${a.invoiceId} • ${a.customer} • ${Formatters.idr(a.amount)}',
                )),
            const SizedBox(height: 8),
            Text(
              'Total Nominal: ${Formatters.idr(total)}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Proses'),
        ),
      ],
    );
  }
}