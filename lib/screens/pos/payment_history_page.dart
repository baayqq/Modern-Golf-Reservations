// Screen: Payment History page
// Tampilkan daftar pembayaran dan alokasinya.
// Menambahkan tombol Print untuk mencetak kwitansi pembayaran sebagai PDF.
import 'package:flutter/material.dart';
import '../../app_scaffold.dart';
import '../../services/invoice_repository.dart';
import 'package:printing/printing.dart';
import '../../services/payment_pdf.dart' as paypdf;
import 'package:modern_golf_reservations/utils/currency.dart';

class PaymentHistoryPage extends StatefulWidget {
  const PaymentHistoryPage({super.key});

  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  final InvoiceRepository _repo = InvoiceRepository();
  final TextEditingController _payerCtrl = TextEditingController();
  DateTime? _filterDate;
  String? _methodFilter; // e.g., cash, card, transfer

  List<PaymentRecord> _payments = [];
  PaymentRecord? _selectedPayment;
  List<AllocationRecord> _allocations = [];

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
    final rows = await _repo.getPayments(
      date: _filterDate,
      payerQuery: _payerCtrl.text.trim().isEmpty
          ? null
          : _payerCtrl.text.trim(),
      method: _methodFilter,
    );
    final items = rows.map((e) {
      final id = (e['id'] as int?) ?? (e['id'] as num).toInt();
      final payer = (e['payer'] as String?) ?? 'Unknown';
      final amount = (e['amount'] is num)
          ? (e['amount'] as num).toDouble()
          : (e['amount'] as double? ?? 0.0);
      final method = e['method'] as String?;
      final date =
          DateTime.tryParse((e['date'] as String?) ?? '') ?? DateTime.now();
      return PaymentRecord(
        id: id,
        payer: payer,
        amount: amount,
        method: method,
        date: date,
      );
    }).toList();
    setState(() {
      _payments = items;
      _selectedPayment = null;
      _allocations = [];
    });
  }

  Future<void> _viewAllocations(PaymentRecord p) async {
    setState(() {
      _selectedPayment = p;
      _allocations = [];
    });
    final rows = await _repo.getAllocationsForPayment(p.id);
    setState(() {
      _allocations = rows.map((e) {
        final id = (e['id'] as int?) ?? (e['id'] as num).toInt();
        final invoiceId =
            (e['invoiceId'] as int?) ?? (e['invoiceId'] as num).toInt();
        final amount = (e['amount'] is num)
            ? (e['amount'] as num).toDouble()
            : (e['amount'] as double? ?? 0.0);
        final customer = (e['customer'] as String?) ?? 'Walk-in';
        final total = (e['total'] is num)
            ? (e['total'] as num).toDouble()
            : (e['total'] as double? ?? 0.0);
        final status = (e['status'] as String?) ?? 'unpaid';
        return AllocationRecord(
          id: id,
          invoiceId: invoiceId,
          amount: amount,
          customer: customer,
          invoiceTotal: total,
          status: status,
        );
      }).toList();
    });
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
      _payerCtrl.clear();
      _methodFilter = null;
    });
    _load();
  }

  @override
  void dispose() {
    _repo.close();
    _payerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Payment History',
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Payment History',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _filters(),
            const SizedBox(height: 16),
            Expanded(child: _paymentTable()),
            const SizedBox(height: 16),
            _allocationsSection(),
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
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline,
                          ),
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
                  const Text('Nama Pembayar'),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 42,
                    child: TextField(
                      controller: _payerCtrl,
                      decoration: const InputDecoration(hintText: 'Cari...'),
                      onSubmitted: (_) => _load(),
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
                  const Text('Metode'),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 42,
                    child: DropdownButtonFormField<String>(
                      value: _methodFilter,
                      items: const [
                        DropdownMenuItem(value: 'cash', child: Text('Cash')),
                        DropdownMenuItem(
                          value: 'credit',
                          child: Text('Kartu Kredit'),
                        ),
                        DropdownMenuItem(value: 'debit', child: Text('Debit')),
                        DropdownMenuItem(value: 'qris', child: Text('QRIS')),
                        // Legacy values for backward compatibility
                        DropdownMenuItem(
                          value: 'card',
                          child: Text('Card (Legacy)'),
                        ),
                        DropdownMenuItem(
                          value: 'transfer',
                          child: Text('Transfer (Legacy)'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _methodFilter = v),
                      decoration: const InputDecoration(
                        hintText: 'Pilih metode',
                      ),
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

  Widget _paymentTable() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final table = Table(
            columnWidths: const {
              0: FixedColumnWidth(140), // payment id
              1: FixedColumnWidth(220), // payer
              2: FixedColumnWidth(180), // amount
              3: FixedColumnWidth(160), // method
              4: FixedColumnWidth(200), // date
              5: FixedColumnWidth(160), // actions
            },
            border: TableBorder.all(
              color: Theme.of(context).colorScheme.outline,
            ),
            children: [
              _headerRow([
                'Payment ID',
                'Payer',
                'Amount',
                'Method',
                'Date',
                'Actions',
              ]),
              ..._payments.map(_paymentRow),
            ],
          );

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

  TableRow _paymentRow(PaymentRecord p) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Text('#${p.id}'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Text(p.payer),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Text(Formatters.idr(p.amount)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Text(p.method ?? '-'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Text(
            '${_two(p.date.day)}/${_two(p.date.month)}/${p.date.year}',
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              FilledButton.tonal(
                onPressed: () => _viewAllocations(p),
                child: const Text('View Detail'),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: () => _printPayment(p),
                child: const Text('Print'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _allocationsSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _selectedPayment == null
                  ? 'Select a payment to view allocations'
                  : 'Allocations for Payment #${_selectedPayment!.id} (${_selectedPayment!.payer})',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            if (_allocations.isEmpty)
              const Text('No allocations for the selected payment')
            else
              Table(
                columnWidths: const {
                  0: FixedColumnWidth(120), // invoice id
                  1: FixedColumnWidth(220), // customer
                  2: FixedColumnWidth(160), // amount
                  3: FixedColumnWidth(160), // invoice total
                  4: FixedColumnWidth(140), // status
                },
                border: TableBorder.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
                children: [
                  _headerRow([
                    'Invoice ID',
                    'Customer',
                    'Allocated Amount',
                    'Invoice Total',
                    'Status',
                  ]),
                  ..._allocations.map(
                    (a) => TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Text('#${a.invoiceId}'),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Text(a.customer),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Text(Formatters.idr(a.amount)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Text(Formatters.idr(a.invoiceTotal)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: _statusChip(a.status),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
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

  String _two(int n) => n.toString().padLeft(2, '0');

  Future<void> _printPayment(PaymentRecord p) async {
    // Pastikan data allocasi tersedia untuk payment ini.
    List<AllocationRecord> allocs = _allocations;
    if (_selectedPayment == null || _selectedPayment!.id != p.id) {
      final rows = await _repo.getAllocationsForPayment(p.id);
      allocs = rows.map((e) {
        final id = (e['id'] as int?) ?? (e['id'] as num).toInt();
        final invoiceId =
            (e['invoiceId'] as int?) ?? (e['invoiceId'] as num).toInt();
        final amount = (e['amount'] is num)
            ? (e['amount'] as num).toDouble()
            : (e['amount'] as double? ?? 0.0);
        final customer = (e['customer'] as String?) ?? 'Walk-in';
        final total = (e['total'] is num)
            ? (e['total'] as num).toDouble()
            : (e['total'] as double? ?? 0.0);
        final status = (e['status'] as String?) ?? 'unpaid';
        return AllocationRecord(
          id: id,
          invoiceId: invoiceId,
          amount: amount,
          customer: customer,
          invoiceTotal: total,
          status: status,
        );
      }).toList();
    }

    // Konversi ke struktur service untuk PDF.
    final pdfAllocations = allocs
        .map((a) => paypdf.PaymentAllocation(
              invoiceId: a.invoiceId,
              customer: a.customer,
              amount: a.amount,
              invoiceTotal: a.invoiceTotal,
              status: a.status,
            ))
        .toList();

    // Cetak PDF tanpa memblok UI; tangani error secara non-blocking.
    Printing.layoutPdf(
      onLayout: (format) => paypdf.generatePaymentPdf(
        paymentId: p.id,
        date: p.date,
        payer: p.payer,
        method: p.method ?? '-',
        amount: p.amount,
        allocations: pdfAllocations,
      ),
    ).catchError((Object e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuka dialog print: $e')),
      );
      return false;
    });
  }
}

class PaymentRecord {
  final int id;
  final String payer;
  final double amount;
  final String? method;
  final DateTime date;
  PaymentRecord({
    required this.id,
    required this.payer,
    required this.amount,
    required this.method,
    required this.date,
  });
}

class AllocationRecord {
  final int id;
  final int invoiceId;
  final double amount;
  final String customer;
  final double invoiceTotal;
  final String status;
  AllocationRecord({
    required this.id,
    required this.invoiceId,
    required this.amount,
    required this.customer,
    required this.invoiceTotal,
    required this.status,
  });
}
