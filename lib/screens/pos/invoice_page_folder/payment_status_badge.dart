// Widget: PaymentStatusBadge
// Menampilkan lencana status pembayaran (Unpaid, Paid, Partial) dengan warna konsisten dari Theme.
// Reusable untuk halaman POS/invoice.
import 'package:flutter/material.dart';
import 'package:modern_golf_reservations/models/invoice_models.dart';

class PaymentStatusBadge extends StatelessWidget {
  final PaymentStatus status;
  const PaymentStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final Color fg;
    late final String label;
    switch (status) {
      case PaymentStatus.unpaid:
        bg = Theme.of(context).colorScheme.tertiaryContainer;
        fg = Theme.of(context).colorScheme.onTertiaryContainer;
        label = 'Unpaid';
        break;
      case PaymentStatus.paid:
        bg = Theme.of(context).colorScheme.secondaryContainer;
        fg = Theme.of(context).colorScheme.onSecondaryContainer;
        label = 'Paid';
        break;
      case PaymentStatus.partial:
        bg = Theme.of(context).colorScheme.primaryContainer;
        fg = Theme.of(context).colorScheme.onPrimaryContainer;
        label = 'Partial';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}