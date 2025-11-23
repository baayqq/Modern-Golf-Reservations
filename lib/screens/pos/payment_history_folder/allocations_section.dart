// Widget: Payment Allocations Section
// Tujuan: Menampilkan alokasi pembayaran untuk payment yang dipilih.
// Catatan: Tampilkan ringkasan dan tabel alokasi; sertakan aksi cetak/unduh.
import 'package:flutter/material.dart';
import '../../../utils/currency.dart';
import '../../../models/payment_models.dart';

class PaymentAllocationsSection extends StatelessWidget {
  final PaymentRecord? selectedPayment;
  final List<AllocationRecord> allocations;
  final VoidCallback? onPrint;
  final VoidCallback? onDownload;
  final String Function(DateTime) formatDate;

  const PaymentAllocationsSection({
    super.key,
    required this.selectedPayment,
    required this.allocations,
    required this.onPrint,
    required this.onDownload,
    required this.formatDate,
  });

  Widget _headerCell(String label, {Alignment alignment = Alignment.centerLeft}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      alignment: alignment,
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (selectedPayment == null) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ID Pembayaran: #${selectedPayment!.id}'),
                      const SizedBox(height: 4),
                      Text('Pembayar: ${selectedPayment!.payer}'),
                      const SizedBox(height: 4),
                      Text('Tanggal: ${formatDate(selectedPayment!.date)}'),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Total: ${Formatters.idr(selectedPayment!.amount)}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (onPrint != null)
                          TextButton(onPressed: onPrint, child: const Text('Cetak')),
                        if (onDownload != null) ...[
                          const SizedBox(width: 8),
                          TextButton(onPressed: onDownload, child: const Text('Unduh')),
                        ]
                      ],
                    )
                  ],
                )
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Table allocations
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
          ),
          child: Row(children: [
            Expanded(child: _headerCell('Invoice ID')),
            Expanded(child: _headerCell('Customer')),
            Expanded(child: _headerCell('Allocated Amount', alignment: Alignment.centerRight)),
            Expanded(child: _headerCell('Invoice Total', alignment: Alignment.centerRight)),
            Expanded(child: _headerCell('Status')),
          ]),
        ),
        const SizedBox(height: 8),
        ...allocations.map((a) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
              ),
            ),
            child: Row(children: [
              Expanded(child: Text('#${a.invoiceId}')),
              Expanded(child: Text(a.customer)),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(Formatters.idr(a.amount)),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(Formatters.idr(a.invoiceTotal)),
                ),
              ),
              Expanded(child: _statusChip(a.status)),
            ]),
          );
        }).toList(),
      ],
    );
  }

  Widget _statusChip(String status) {
    Color bg;
    switch (status) {
      case 'paid':
        bg = Colors.green.shade100;
        break;
      case 'partial':
        bg = Colors.orange.shade100;
        break;
      default:
        bg = Colors.red.shade100;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}