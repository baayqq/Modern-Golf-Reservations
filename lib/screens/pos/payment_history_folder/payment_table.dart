// Widget: Payment Table
// Tujuan: Menampilkan daftar pembayaran dengan aksi Lihat, Cetak, dan Download.
// Catatan: Responsif dengan LayoutBuilder; gunakan tabel saat lebar cukup.
import 'package:flutter/material.dart';
import '../../../utils/currency.dart';
import '../../../models/payment_models.dart';

typedef OnPaymentAction = void Function(PaymentRecord payment);
typedef FormatDate = String Function(DateTime date);

class PaymentTable extends StatelessWidget {
  final List<PaymentRecord> payments;
  final OnPaymentAction onView;
  final OnPaymentAction onPrint;
  final OnPaymentAction onDownload;
  final FormatDate formatDate;

  const PaymentTable({
    super.key,
    required this.payments,
    required this.onView,
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
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 800;
      if (!isWide) {
        // Card list view for narrow screens
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final p = payments[index];
            return Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${p.payer} • ${p.method ?? '-'}'),
                    const SizedBox(height: 4),
                    Text(formatDate(p.date)),
                    const SizedBox(height: 6),
                    Text(Formatters.idr(p.amount)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        TextButton(onPressed: () => onView(p), child: const Text('Lihat Detail')),
                        const SizedBox(width: 8),
                        TextButton(onPressed: () => onPrint(p), child: const Text('Cetak')),
                        const SizedBox(width: 8),
                        TextButton(onPressed: () => onDownload(p), child: const Text('Download')),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemCount: payments.length,
        );
      }

      // Table view for wide screens
      return Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(children: [
              Expanded(child: _headerCell('Pembayar')),
              Expanded(child: _headerCell('Metode')),
              Expanded(child: _headerCell('Tanggal')),
              Expanded(child: _headerCell('Nominal', alignment: Alignment.centerRight)),
              const SizedBox(width: 12),
              _headerCell('Aksi'),
            ]),
          ),
          const SizedBox(height: 8),
          ...payments.map((p) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                ),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(p.payer)),
                  Expanded(child: Text(p.method ?? '-')),
                  Expanded(child: Text(formatDate(p.date))),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(Formatters.idr(p.amount)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    children: [
                      TextButton(onPressed: () => onView(p), child: const Text('Lihat')),
                      TextButton(onPressed: () => onPrint(p), child: const Text('Cetak')),
                      TextButton(onPressed: () => onDownload(p), child: const Text('Unduh')),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      );
    });
  }
}