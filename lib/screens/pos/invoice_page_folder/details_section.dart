// Widget: InvoiceDetailsSection
// Menampilkan detail item untuk invoice terpilih dan tombol export ke PDF.
import 'package:flutter/material.dart';
import 'package:modern_golf_reservations/models/invoice_models.dart';
import 'package:modern_golf_reservations/utils/currency.dart';

class InvoiceDetailsSection extends StatelessWidget {
  final InvoiceItem? selectedInvoice;
  final List<InvoiceLine> selectedItems;
  final String Function(DateTime dt) formatDate;
  // Tombol export PDF dihapus karena sudah ada tombol Print & Download di action bar.

  const InvoiceDetailsSection({
    super.key,
    required this.selectedInvoice,
    required this.selectedItems,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedInvoice == null) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            'Klik salah satu invoice untuk melihat detail item transaksi.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final inv = selectedInvoice!;
    final total = selectedItems.fold<double>(0.0, (s, e) => s + e.price * e.qty);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Invoice #${inv.id} - ${inv.customer}',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text('Tanggal: ${formatDate(inv.date)}'),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final table = Table(
                  columnWidths: const {
                    0: FixedColumnWidth(220),
                    1: FixedColumnWidth(80),
                    2: FixedColumnWidth(160),
                    3: FixedColumnWidth(180),
                  },
                  border: TableBorder.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  children: [
                    _headerRow(context, ['Item', 'Qty', 'Price', 'Subtotal']),
                    ...selectedItems.map(
                      (it) => TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Text(it.name),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Text('${it.qty}'),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Text(Formatters.idr(it.price)),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Text(Formatters.idr(it.price * it.qty)),
                          ),
                        ],
                      ),
                    ),
                    TableRow(
                      children: [
                        const SizedBox.shrink(),
                        const SizedBox.shrink(),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: const Text(
                            'Total',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Text(
                            Formatters.idr(total),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ],
                );

                return Scrollbar(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: constraints.maxWidth),
                      child: table,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            // Tombol export PDF dihilangkan agar tidak duplikasi dengan action bar print & download.
          ],
        ),
      ),
    );
  }

  TableRow _headerRow(BuildContext context, List<String> headers) {
    return TableRow(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      children: headers
          .map(
            (h) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Text(
                h,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          )
          .toList(),
    );
  }
}