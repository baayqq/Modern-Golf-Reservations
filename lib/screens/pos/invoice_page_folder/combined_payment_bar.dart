import 'package:flutter/material.dart';
import 'package:modern_golf_reservations/models/invoice_models.dart';

class CombinedPaymentBar extends StatelessWidget {
  final TextEditingController payerController;
  final PaymentMode paymentMode;
  final ValueChanged<PaymentMode> onChangePaymentMode;
  final String paymentMethod;
  final ValueChanged<String> onChangePaymentMethod;
  final VoidCallback onCombinedPay;
  final VoidCallback onIndividualPay;

  final int selectedCount;

  const CombinedPaymentBar({
    super.key,
    required this.payerController,
    required this.paymentMode,
    required this.onChangePaymentMode,
    required this.paymentMethod,
    required this.onChangePaymentMethod,
    required this.onCombinedPay,
    required this.onIndividualPay,
    required this.selectedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nama Pembayar (contoh: Pemain A)'),
            const SizedBox(height: 6),
            SizedBox(
              height: 42,
              child: TextField(
                controller: payerController,
                decoration: const InputDecoration(
                  hintText: 'Masukkan nama pembayar...',
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Mode Pembayaran'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Gabungan'),
                  selected: paymentMode == PaymentMode.combined,
                  onSelected: (sel) {
                    if (sel) onChangePaymentMode(PaymentMode.combined);
                  },
                ),
                ChoiceChip(
                  label: const Text('Individu'),
                  selected: paymentMode == PaymentMode.individual,
                  onSelected: (sel) {
                    if (sel) onChangePaymentMode(PaymentMode.individual);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Metode Pembayaran'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                ChoiceChip(
                  label: const Text('Cash'),
                  selected: paymentMethod == 'cash',
                  onSelected: (sel) {
                    if (sel) onChangePaymentMethod('cash');
                  },
                ),
                ChoiceChip(
                  label: const Text('Kartu Kredit'),
                  selected: paymentMethod == 'credit',
                  onSelected: (sel) {
                    if (sel) onChangePaymentMethod('credit');
                  },
                ),
                ChoiceChip(
                  label: const Text('Debit'),
                  selected: paymentMethod == 'debit',
                  onSelected: (sel) {
                    if (sel) onChangePaymentMethod('debit');
                  },
                ),
                ChoiceChip(
                  label: const Text('QRIS'),
                  selected: paymentMethod == 'qris',
                  onSelected: (sel) {
                    if (sel) onChangePaymentMethod('qris');
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (paymentMode == PaymentMode.combined)
              SizedBox(
                height: 42,
                child: ElevatedButton(
                  onPressed: selectedCount >= 2 ? onCombinedPay : null,
                  child: const Text('Terima Pembayaran Gabungan'),
                ),
              )
            else
              SizedBox(
                height: 42,
                child: ElevatedButton(
                  onPressed: onIndividualPay,
                  child: const Text('Bayar Invoice Terpilih'),
                ),
              ),
            if (paymentMode == PaymentMode.combined && selectedCount < 2)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Pilih minimal 2 invoice untuk pembayaran gabungan',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}