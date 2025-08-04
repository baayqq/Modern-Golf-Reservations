import 'package:flutter/material.dart';
import '../../app_scaffold.dart';

class InvoicePage extends StatefulWidget {
  const InvoicePage({super.key});

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  final List<InvoiceItem> _invoices = [
    InvoiceItem(
      id: '9189',
      customer: 'Alexander Dippo',
      total: 24272000.00,
      status: PaymentStatus.unpaid,
      date: DateTime(2025, 5, 31, 7, 50),
    ),
  ];
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'All Unpaid Invoices',
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'All Unpaid Invoices',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _btn(
                  label: 'Combine Invoices',
                  color: const Color(0xFF198754),
                  onPressed: _selected.isEmpty ? null : () {},
                ),
                _btn(
                  label: 'Go to POS',
                  color: const Color(0xFF0D6EFD),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                _btn(
                  label: 'Go to Invoice List',
                  color: const Color(0xFF0D6EFD),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(child: _invoiceTable()),
            const SizedBox(height: 12),
            Center(
              child: Text(
                '© 2024 | IT Department.',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _btn({
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 36,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Text(label),
      ),
    );
  }

  Widget _invoiceTable() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Table(
        columnWidths: const {
          0: FixedColumnWidth(60), // select
          1: FixedColumnWidth(120), // invoice id
          2: FlexColumnWidth(), // customer name
          3: FixedColumnWidth(180), // total
          4: FixedColumnWidth(160), // status
          5: FixedColumnWidth(200), // date
        },
        border: TableBorder.all(color: const Color(0xFFDEE2E6)),
        children: [
          _headerRow([
            'Select',
            'Invoice ID',
            'Customer Name',
            'Total Amount (Rp.)',
            'Payment Status',
            'Date',
          ]),
          ..._invoices.map(_dataRow),
        ],
      ),
    );
  }

  TableRow _headerRow(List<String> headers) {
    return TableRow(
      decoration: const BoxDecoration(color: Color(0xFFF8F9FA)),
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

  TableRow _dataRow(InvoiceItem inv) {
    final selected = _selected.contains(inv.id);
    return TableRow(
      children: [
        // Select
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Checkbox(
            value: selected,
            onChanged: (v) {
              setState(() {
                if (v == true) {
                  _selected.add(inv.id);
                } else {
                  _selected.remove(inv.id);
                }
              });
            },
          ),
        ),
        // Invoice ID
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Text(inv.id),
        ),
        // Customer Name
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Text(inv.customer),
        ),
        // Total Amount
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Text(_formatCurrency(inv.total)),
        ),
        // Payment Status (badge)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: _statusBadge(inv.status),
        ),
        // Date
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Text(_formatDate(inv.date)),
        ),
      ],
    );
  }

  Widget _statusBadge(PaymentStatus status) {
    late final Color bg;
    late final Color fg;
    late final String label;
    switch (status) {
      case PaymentStatus.unpaid:
        bg = const Color(0xFFFFF3CD);
        fg = const Color(0xFF856404);
        label = 'Unpaid';
        break;
      case PaymentStatus.paid:
        bg = const Color(0xFFD4EDDA);
        fg = const Color(0xFF155724);
        label = 'Paid';
        break;
      case PaymentStatus.partial:
        bg = const Color(0xFFD1ECF1);
        fg = const Color(0xFF0C5460);
        label = 'Partial';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bg),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _formatCurrency(double v) {
    // Simple currency format: 24,272,000.00
    final s = v.toStringAsFixed(2);
    final parts = s.split('.');
    final whole = parts[0];
    final decimals = parts[1];
    final buffer = StringBuffer();
    for (int i = 0; i < whole.length; i++) {
      final idx = whole.length - i - 1;
      buffer.write(whole[idx]);
      if (i % 3 == 2 && idx != 0) buffer.write(',');
    }
    final reversed = buffer.toString().split('').reversed.join();
    return '$reversed.$decimals';
  }

  String _formatDate(DateTime dt) {
    // 31/05/2025, 07:50 AM
    final two = (int n) => n.toString().padLeft(2, '0');
    final d = two(dt.day);
    final m = two(dt.month);
    final y = dt.year;
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = two(dt.minute);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$d/$m/$y, ${two(h)}:$minute $ampm';
  }
}

enum PaymentStatus { unpaid, paid, partial }

class InvoiceItem {
  final String id;
  final String customer;
  final double total;
  final PaymentStatus status;
  final DateTime date;

  InvoiceItem({
    required this.id,
    required this.customer,
    required this.total,
    required this.status,
    required this.date,
  });
}
