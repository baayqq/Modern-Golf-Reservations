import 'package:flutter/material.dart';
import '../../app_scaffold.dart';
import '../../services/invoice_repository.dart';
import 'package:intl/intl.dart';

class InvoicePage extends StatefulWidget {
  const InvoicePage({super.key});

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  final InvoiceRepository _repo = InvoiceRepository();
  List<InvoiceItem> _invoices = [];
  InvoiceItem? _selectedInvoice;
  List<InvoiceLine> _selectedItems = [];
  DateTime? _filterDate;
  final TextEditingController _filterNameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _repo.init();
    await _load();
  }

  Future<void> _load() async {
    final rows = await _repo.getInvoices(
      date: _filterDate,
      customerQuery: _filterNameCtrl.text.trim().isEmpty
          ? null
          : _filterNameCtrl.text.trim(),
    );
    setState(() {
      _invoices = rows.map((e) {
        final idVal = e['id'] as int? ?? (e['id'] as num).toInt();
        final statusStr = (e['status'] as String?) ?? 'unpaid';
        final status = switch (statusStr) {
          'paid' => PaymentStatus.paid,
          'partial' => PaymentStatus.partial,
          _ => PaymentStatus.unpaid,
        };
        return InvoiceItem(
          id: idVal.toString(),
          customer: (e['customer'] as String?) ?? 'Walk-in',
          total: (e['total'] is num)
              ? (e['total'] as num).toDouble()
              : (e['total'] as double? ?? 0.0),
          status: status,
          date:
              DateTime.tryParse((e['date'] as String?) ?? '') ?? DateTime.now(),
        );
      }).toList();
    });
  }

  Future<void> _viewDetails(InvoiceItem inv) async {
    setState(() {
      _selectedInvoice = inv;
      _selectedItems = [];
    });
    final rows = await _repo.getItemsForInvoice(int.parse(inv.id));
    setState(() {
      _selectedItems = rows.map((e) {
        final name = (e['name'] as String?) ?? '';
        final qty =
            (e['qty'] as int?) ??
            (e['qty'] is num ? (e['qty'] as num).toInt() : 0);
        final price = (e['price'] is num)
            ? (e['price'] as num).toDouble()
            : (e['price'] as double? ?? 0.0);
        return InvoiceLine(name: name, qty: qty, price: price);
      }).toList();
    });
  }

  void _exportPdf() {
    if (_selectedInvoice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih invoice terlebih dahulu')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Exported invoice #${_selectedInvoice!.id} to PDF (dummy)',
        ),
      ),
    );
  }

  Future<void> _pickFilterDate() async {
    final now = DateTime.now();
    final res = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      initialDate: _filterDate ?? now,
    );
    if (res != null) setState(() => _filterDate = res);
  }

  void _clearFilters() {
    setState(() {
      _filterDate = null;
      _filterNameCtrl.clear();
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Invoices',
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Invoice List',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _filters(),
            const SizedBox(height: 16),
            Expanded(child: _invoiceTable()),
            const SizedBox(height: 16),
            _detailsSection(),
            const SizedBox(height: 12),
            Center(
              child: Text(
                '© 2025 | Fitri Dwi Astuti.',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filters() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Filter Tanggal'),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 42,
                    child: InkWell(
                      onTap: _pickFilterDate,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Theme.of(context).colorScheme.outline),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _filterDate == null
                              ? 'dd/mm/yyyy'
                              : '${_two(_filterDate!.day)}/${_two(_filterDate!.month)}/${_filterDate!.year}',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nama Pemain'),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 42,
                    child: TextField(
                      controller: _filterNameCtrl,
                      decoration: const InputDecoration(hintText: 'Cari...'),
                      onSubmitted: (_) => _load(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 42,
              child: ElevatedButton(
                onPressed: _load,
                // Gunakan warna dari tema agar konsisten
                child: const Text('Cari'),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 42,
              child: ElevatedButton(
                onPressed: _clearFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                ),
                child: const Text('Clear'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _invoiceTable() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final table = Table(
            columnWidths: const {
              0: FixedColumnWidth(140), // invoice id
              1: FlexColumnWidth(), // customer name
              2: FixedColumnWidth(180), // total
              3: FixedColumnWidth(160), // status
              4: FixedColumnWidth(200), // date
              5: FixedColumnWidth(160), // actions
            },
            border: TableBorder.all(color: Theme.of(context).colorScheme.outline),
            children: [
              _headerRow([
                'Invoice ID',
                'Customer Name',
                'Total Amount',
                'Payment Status',
                'Date',
                'Actions',
              ]),
              ..._invoices.map(_dataRow),
            ],
          );

          // Scroll vertikal & horizontal untuk mencegah overflow
          return Scrollbar(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: table,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  TableRow _headerRow(List<String> headers) {
    return TableRow(
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest),
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
    return TableRow(
      children: [
        // Invoice ID (clickable)
        InkWell(
          onTap: () => _viewDetails(inv),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text(
              inv.id,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        // Customer Name
        InkWell(
          onTap: () => _viewDetails(inv),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text(inv.customer),
          ),
        ),
        // Total Amount
        InkWell(
          onTap: () => _viewDetails(inv),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text(_formatCurrency(inv.total)),
          ),
        ),
        // Payment Status (badge)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: _statusBadge(inv.status),
        ),
        // Date
        InkWell(
          onTap: () => _viewDetails(inv),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text(_formatDate(inv.date)),
          ),
        ),
        // Actions: Export to PDF (dummy)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: SizedBox(
            height: 28,
            child: FilledButton.tonal(
              onPressed: () {
                setState(() => _selectedInvoice = inv);
                _exportPdf();
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Theme.of(context).colorScheme.onSecondary,
              ),
              child: const Text('Export to PDF'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _detailsSection() {
    if (_selectedInvoice == null) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            'Klik salah satu invoice untuk melihat detail item transaksi.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }

    final inv = _selectedInvoice!;
    final total = _selectedItems.fold<double>(
      0.0,
      (s, e) => s + e.price * e.qty,
    );
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
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text('Tanggal: ${_formatDate(inv.date)}'),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final table = Table(
                  columnWidths: const {
                    // Pastikan kolom Item cukup lebar agar teks tidak memecah per huruf
                    0: FixedColumnWidth(220),
                    1: FixedColumnWidth(80),
                    2: FixedColumnWidth(160),
                    3: FixedColumnWidth(180),
                  },
                  border: TableBorder.all(color: Theme.of(context).colorScheme.outline),
                  children: [
                    _headerRow(['Item', 'Qty', 'Price', 'Subtotal']),
                    ..._selectedItems.map(
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
                            child: Text(_formatCurrency(it.price)),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Text(_formatCurrency(it.price * it.qty)),
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
                            _formatCurrency(total),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ],
                );

                // Pastikan tabel minimal selebar area konten untuk mencegah kolom menyempit ekstrem
                return Scrollbar(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth,
                      ),
                      child: table,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: _exportPdf,
                    child: const Text('Export to PDF'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(PaymentStatus status) {
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

  String _formatCurrency(double v) {
    final format = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    return format.format(v);
  }

  String _formatDate(DateTime dt) {
    // 31/05/2025, 07:50 AM
    final d = _two(dt.day);
    final m = _two(dt.month);
    final y = dt.year;
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = _two(dt.minute);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$d/$m/$y, ${_two(h)}:$minute $ampm';
  }

  String _two(int n) => n.toString().padLeft(2, '0');
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

class InvoiceLine {
  final String name;
  final int qty;
  final double price;

  InvoiceLine({required this.name, required this.qty, required this.price});
}
