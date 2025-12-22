import 'package:flutter/material.dart';
import 'package:modern_golf_reservations/models/invoice_models.dart';
import 'package:modern_golf_reservations/utils/currency.dart';

class CombinedDetailsSection extends StatelessWidget {
  final Set<int> selectedInvoiceIds;
  final List<InvoiceItem> invoices;
  final Map<int, List<InvoiceLine>> combinedSelectedItems;
  final String Function(DateTime dt) formatDate;

  const CombinedDetailsSection({
    super.key,
    required this.selectedInvoiceIds,
    required this.invoices,
    required this.combinedSelectedItems,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    final ids = selectedInvoiceIds.toList();
    if (ids.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detail Invoice (Gabungan)',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ...ids.map((id) {
              final inv = invoices.firstWhere(
                (e) => int.tryParse(e.id) == id,
                orElse: () => invoices.first,
              );
              final items = combinedSelectedItems[id] ?? const <InvoiceLine>[];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invoice #${inv.id} - ${inv.customer}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text('Tanggal: ${formatDate(inv.date)}'),
                    const SizedBox(height: 8),
                    _CombinedItemsTable(items: items),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _CombinedItemsTable extends StatefulWidget {
  final List<InvoiceLine> items;
  const _CombinedItemsTable({required this.items});

  @override
  State<_CombinedItemsTable> createState() => _CombinedItemsTableState();
}

class _CombinedItemsTableState extends State<_CombinedItemsTable> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.items.fold<double>(0.0, (s, e) => s + e.qty * e.price);
    return LayoutBuilder(
      builder: (context, constraints) {
        final table = Table(
          columnWidths: const {
            0: FixedColumnWidth(220),
            1: FixedColumnWidth(80),
            2: FixedColumnWidth(160),
            3: FixedColumnWidth(180),
          },
          border: TableBorder.all(color: Theme.of(context).colorScheme.outline),
          children: [
            _headerRow(context, ['Item', 'Qty', 'Price', 'Subtotal']),
            ...widget.items.map(
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
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Text(
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
          controller: _scrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: table,
            ),
          ),
        );
      },
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